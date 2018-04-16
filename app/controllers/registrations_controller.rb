class RegistrationsController < ApplicationController
  layout 'static'

  rescue_from ActiveRecord::RecordInvalid, with: :render_errors

  def new
    @form = RegistrationForm.new(params)
    @form.ignore_existing_site = @form.existing_site_url?
  end

  def create
    @form = RegistrationForm.new(params)

    session[:new_site_url] = @form.site_url

    return unless validate_url

    if params[:signup_with_email]
      signup_with_email
    else
      signup_with_google
    end
  end

  private

  def validate_url
    unless @form.valid?
      flash[:error] = 'Your URL is not valid. Please double-check it and try again.'
      redirect_to users_sign_up_path(url: @form.site_url)
      return false
    end

    if @form.existing_site_url? && !@form.ignore_existing_site
      render :new
      return false
    end

    true
  end

  def signup_with_email
    @form.validate!

    CreateSite.new(@form.site, @form.user, referral_token: session[:referral_token]).call
    sign_in(@form.user)

    redirect_to new_site_site_element_path(@form.site)
  end

  def signup_with_google
    redirect_to oauth_login_path(action: 'google_oauth2')
  end

  def render_errors(exception)
    flash.now[:error] = exception.record.errors.full_messages.to_sentence
    render :new
  end
end
