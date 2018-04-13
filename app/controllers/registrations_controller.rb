class RegistrationsController < ApplicationController
  layout 'static'

  def new
    @form = RegistrationForm.new(params)
  end

  def create
    @form = RegistrationForm.new(params)

    session[:new_site_url] = @form.site_url

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

    if Site.by_url(@form.site_url).any?
      redirect_to new_user_session_path(existing_url: @form.site_url)
      return false
    end

    true
  end

  def signup_with_email
    return unless validate_url

    @form.user.save!
    CreateSite.new(@form.site, @form.user, referral_token: session[:referral_token]).call
    sign_in(@form.user)
    redirect_to new_site_site_element_path(@form.site)
  rescue ActiveRecord::RecordInvalid => e
    flash[:error] = e.record.errors.full_messages.to_sentence
    render :new
  end

  def signup_with_google
    return unless validate_url

    redirect_to oauth_login_path(action: 'google_oauth2')
  end
end
