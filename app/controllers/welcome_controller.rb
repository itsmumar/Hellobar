class WelcomeController < ApplicationController
  layout 'static'

  before_action :require_no_user, only: [:index, :email_quickstart]

  def index
    Analytics.track(*current_person_type_and_id, "Homepage")
    set_site_url
  end

  def email_quickstart
    @signup_type = :email
    Analytics.track(*current_person_type_and_id, "Homepage - Email Signup")
    set_site_url
    render action: "index"
  end

  private

  def set_site_url
    if(session[:new_site_url])
      @site_url = session[:new_site_url]
      session.delete(:new_site_url)
    end
  end
end
