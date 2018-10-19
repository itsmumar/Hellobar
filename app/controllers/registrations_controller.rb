class RegistrationsController < ApplicationController
  before_action :require_no_user, except: [:subscribe]

  layout 'static'

  rescue_from ActiveRecord::RecordInvalid, with: :render_errors

  def new
    cookies[:the_plan] = 'paid' if params[:plan].present? && params[:plan] =~ /(growth|elite)/
    @form = RegistrationForm.new(params, cookies)
    @form.ignore_existing_site = @form.existing_site_url?
  end

  def create
    @form = RegistrationForm.new(params, cookies)

    session[:new_site_url] = @form.site_url

    return unless validate_url

    if params[:signup_with_email]
      signup_with_email
    else
      signup_with_google
    end
  end

  def subscribe
    @plan = params[:plan].split('-')
    @form = PaymentForm.new(params[:credit_card])

    render layout: 'static'
  end

  private

  def allowed_url?
    return true unless Site.banned_sites.include?(URI.parse(@form.site.url).host.downcase)
  end

  def validate_url
    unless @form.site.valid?
      flash.now[:error] = 'Your URL is not valid. Please double-check it and try again.'
      render :new
      return false
    end

    unless @form.accept_terms_and_conditions
      flash.now[:error] = 'Your must accept Terms of Use and Privacy Policy.'
      render :new
      return false
    end

    if @form.existing_site_url? && !@form.ignore_existing_site
      @form.ignore_existing_site = true
      render :new
      return false
    end

    unless allowed_url?
      flash.now[:error] = Site.url_error_messages(URI.parse(@form.site.url).host.downcase)
      render :new
      return false
    end
    true
  end

  def signup_with_email
    user = CreateUserFromForm.new(@form, cookies).call
    sign_in(user)

    site = CreateSite.new(@form.site, @form.user, cookies: cookies, referral_token: session[:referral_token]).call
    sign_in(@form.user)
    if @form.plan.present?
      redirect_to subscribe_registration_path(@form.plan)
    else
      flash[:event] = { category: 'Signup', action: 'signup-email' }
      redirect_to new_site_site_element_path(site)
    end
  end

  def signup_with_google
    redirect_to oauth_login_path(action: 'google_oauth2')
  end

  def render_errors(exception)
    flash.now[:error] = exception.record.errors.full_messages.to_sentence
    render :new
  end
end
