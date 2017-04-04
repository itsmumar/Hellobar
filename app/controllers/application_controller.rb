class ApplicationController < ActionController::Base
  include Hello::InternalAnalytics
  include ActionView::Helpers::NumberHelper
  serialization_scope :current_user

  protect_from_forgery with: :exception

  helper_method :access_token, :current_admin, :impersonated_user, :current_site, :visitor_id, :ab_variation,
    :ab_variation_or_nil

  before_action :record_tracking_param
  before_action :track_h_visit
  before_action :set_raven_context
  after_action :store_last_requested_path

  rescue_from ::Google::Apis::AuthorizationError do |exception|
    raise exception if impersonated_user # we can't authenticate for impersonated users
    return unless exception.to_s =~ /Unauthorized/

    sign_out current_user             # kill cookies
    redirect_to '/auth/google_oauth2' # log in again to refresh token
  end

  def access_token
    @access_token ||= Digest::SHA256.hexdigest(['hellobar', remote_ip, user_agent, access_cookie, 'a776b'].join)
  end

  def access_cookie
    cookies[:adxs] ||= {
      value: Digest::SHA256.hexdigest(['a', rand(10_000), Time.now.to_f, user_agent, 'd753d'].collect(&:to_s).join),
      expires: 90.days.from_now,
      httponly: true
    }
  end

  delegate :user_agent, to: :request

  delegate :remote_ip, to: :request

  def current_admin
    return nil if @current_admin == false
    @current_admin ||= Admin.validate_session(access_token, session[:admin_token]) || false
  end

  def require_admin
    return redirect_to(admin_access_path) unless current_admin
    return unless current_admin.needs_to_set_new_password?

    redirect_to(admin_reset_password_path) unless URI.parse(url_for).path == admin_reset_password_path
  end

  def require_pro_managed_subscription
    redirect_to root_path unless current_site.pro_managed_subscription?
  end

  def require_no_user
    return unless current_user

    if current_user.sites.empty?
      redirect_to new_site_path
    elsif current_user.temporary? && current_user.sites.none? { |s| s.site_elements.any? }
      redirect_to new_site_site_element_path(current_site)
    else
      redirect_to site_path(current_site)
    end
  end

  def after_sign_in_path_for(resource)
    if current_user.should_send_to_new_site_element_path?
      new_site_site_element_path(current_user.sites.script_not_installed_db.last)

    elsif current_user.sites.any?
      # Use last site viewed if available
      s = cookies[:lsv] && current_user.sites.where(id: cookies[:lsv]).first
      stored_location_for(resource) || site_path(s || current_user.sites.last)

    else
      new_site_path
    end
  end

  def current_user
    impersonated_user || super
  end

  def authenticate_user!
    impersonated_user ? true : super
  end

  def impersonated_user
    return unless current_admin && session[:impersonated_user]

    impersonated_user = User.find_by(id: session[:impersonated_user])
    impersonated_user.is_impersonated = true
    impersonated_user
  end

  def current_site
    @current_site ||= begin
      if current_user && session[:current_site]
        current_user.sites.where(id: session[:current_site]).first || current_user.sites.first
      elsif current_user
        current_user.sites.first
      end
    end
  end

  def record_tracking_param
    Hello::TrackingParam.track(params[:trk]) if params[:trk]
  end

  def track_h_visit
    return unless params[:hbt]

    track_params = { h_type: params[:hbt] }
    if params[:sid] # If site element is given, attach the site element id and site id
      site_element = SiteElement.where(id: params[:sid]).first
      if site_element
        track_params[:site_element_id] = site_element.id
        track_params[:site_id] = site_element.site.id if site_element.site
      end
    end
    Analytics.track(*current_person_type_and_id, 'H Visit', track_params)
  end

  def set_raven_context
    Raven.user_context id: current_user.try(:id)

    # TODO: change to `params.to_unsafe_h` when Rails is upgraded to 4.2+
    Raven.extra_context params: params.to_h, url: request.url
  end

  def load_site
    @site ||= current_user.sites.find(params[:site_id]) if current_user && params[:site_id]
  end

  def store_last_requested_path
    # used primarily to detect page refreshes
    session[:last_requested_path] = request.path if request.format == :html
  end

  def page_refresh?
    request.path == session[:last_requested_path]
  end

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(_resource_or_scope)
    logout_confirmation_path
  end
end
