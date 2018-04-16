class WelcomeController < ApplicationController
  layout 'static'

  before_action :require_no_user, only: %i[index]

  def index
    set_site_url
  end

  private

  def set_site_url
    return unless stored_url

    @site_url = stored_url
    session.delete(:new_site_url)
  end

  def stored_url
    session[:new_site_url]
  end
end
