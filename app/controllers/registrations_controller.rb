class RegistrationsController < ApplicationController
  layout 'static'
  before_action :build_site, :build_user

  def new
  end

  def create
    cookies.permanent[:registration_url] = @site.url
    session[:new_site_url] = @site.url

    if params[:signup_with_email]
      signup_with_email
    else
      signup_with_google
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password)
  end

  def build_user
    @user = User.new
  end

  def build_site
    @site = Site.new(url: params[:site_url])
  end

  def validate_url
    build_site

    unless @site.valid?
      flash[:error] = 'Your URL is not valid. Please double-check it and try again.'
      redirect_to new_registration_path(url: @site.url)
      return false
    end

    if Site.by_url(@site.url).any?
      redirect_to new_user_session_path(existing_url: @site.url)
      return false
    end

    true
  end

  def signup_with_email
    return unless validate_url

    if @user.update(user_params)
      CreateSite.new(@site, @user, referral_token: session[:referral_token]).call
      sign_in(@user)
      redirect_to new_site_site_element_path(@site)
    else
      flash[:error] = @user.errors.full_messages.to_sentence
      render :new
    end
  end

  def signup_with_google
    return unless validate_url

    redirect_to oauth_login_path(action: 'google_oauth2')
  end
end
