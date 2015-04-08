class WelcomeController < ApplicationController
  layout 'static'

  before_action :require_no_user, only: :index

  def index
    Analytics.track(*current_person_type_and_id, "Homepage")
    if(session[:new_site_url])
      @site_url = session[:new_site_url]
      session.delete(:new_site_url)
    end
  end
end
