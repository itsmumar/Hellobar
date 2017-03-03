class WelcomeController < ApplicationController
  layout 'static'

  before_action :require_no_user, only: [:index, :email_quickstart]

  def index
    @last_logged_in_user = User.find_by(email: cookies[:login_email])
    Analytics.track(*current_person_type_and_id, 'Homepage')
    set_site_url
  end

  def email_quickstart
    @signup_type = :email
    Analytics.track(*current_person_type_and_id, 'Homepage - Email Signup')
    set_site_url
    render action: 'index'
  end

  private

  def set_site_url
    if stored_url
      @site_url = stored_url

      session.delete(:new_site_url)
    end
  end

  def stored_url
    session[:new_site_url] || cookies[:registration_url]
  end
end
