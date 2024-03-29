class ApplicationController < ActionController::Base
  include Hello::InternalAnalytics
  include ActionView::Helpers::NumberHelper
  serialization_scope :current_user

  protect_from_forgery with: :exception

  helper_method :access_token, :current_admin, :impersonated_user,
    :current_site, :visitor_id, :ab_variation, :ab_variation_or_nil

  before_action :set_raven_context
  before_action :require_credit_card
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

  def current_admin
    return nil if @current_admin == false
    @current_admin ||= Admin.validate_session(session[:admin_token]) || false
  end

  def require_pro_managed_subscription
    redirect_to root_path unless current_site.pro_managed?
  end

  def require_no_user
    return unless current_user

    redirect_to after_sign_in_path_for(current_user)
  end

  def require_credit_card
    return unless current_user
    return if current_user.credit_cards.exists?
    return if current_admin
    return redirect_to new_credit_card_path if cookies[:promotional_signup] == 'true' && cookies[:cc] == '1'
    return redirect_to new_credit_card_path if current_user.affiliate_information&.partner&.require_credit_card
  end

  def after_sign_in_path_for(user)
    return_url = stored_location_for(user)

    if return_url.present?
      return_url
    elsif user.sites.empty?
      new_site_path
    elsif user.sites.count == 1 && user.site_elements.empty?
      new_site_site_element_path(current_site)
    else
      site_path(current_site)
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
    @current_site ||=
      if current_user && session[:current_site].present?
        current_user.sites.where(id: session[:current_site]).first || current_user.sites.last
      elsif current_user && cookies[:lsv].present?
        current_user.sites.where(id: cookies[:lsv]).first || current_user.sites.last
      elsif current_user
        current_user.sites.last
      end
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

  def record_invalid(e)
    respond_to do |format|
      format.json do
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
