class ApplicationController < ActionController::Base
  include Hello::InternalAnalytics
  include ActionView::Helpers::NumberHelper
  serialization_scope :current_user

  protect_from_forgery with: :exception

  helper_method :access_token, :current_admin, :impersonated_user,
    :current_site, :visitor_id, :ab_variation, :ab_variation_or_nil

  before_action :record_tracking_param
  before_action :track_h_visit
  before_action :set_raven_context
  before_action :identify_visitors
  after_action :store_last_requested_path

  delegate :remote_ip, to: :request
  delegate :user_agent, to: :request

  rescue_from ActionController::UnknownFormat do
    head :not_found
  end

  def access_token
    @access_token ||= Digest::SHA256.hexdigest(['hellobar', remote_ip, user_agent, access_cookie, 'a776b'].join)
  end

  def access_cookie
    cookies[:adxs] ||= {
      value: Digest::SHA256.hexdigest(['a', rand(10_000), Time.current.to_f, user_agent, 'd753d'].collect(&:to_s).join),
      expires: 90.days.from_now,
      httponly: true
    }
  end

  # needed to expose cookies (private method) to InternalAnalytics
  def cookies
    super
  end

  def current_admin
    return nil if @current_admin == false
    @current_admin ||= Admin.validate_session(session[:admin_token]) || false
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
    return unless current_admin && session[:impersonated_user].present?

    impersonated_user = User.find_by(id: session[:impersonated_user])

    unless impersonated_user
      session.delete(:impersonated_user)
      return
    end

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

  def identify_visitors
    # call current_person_type_and_id to identify previously anonymous users
    current_person_type_and_id
  end

  def set_raven_context
    Raven.user_context(id: current_user.id, email: current_user.email) if current_user
    Raven.extra_context params: params.to_unsafe_h, url: request.url
  end

  def load_site
    @site ||= current_user.sites.find(params[:site_id]) if current_user && params[:site_id]
  end

  def store_last_requested_path
    # used primarily to detect page refreshes
    session[:last_requested_path] = request.path if request.format == :html
  end

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(_resource_or_scope)
    logout_confirmation_path
  end

  def error_response(error)
    respond_to do |format|
      format.html { render html: error, status: error }
      format.json { render json: { error: error }, status: error }
    end
  end
end
