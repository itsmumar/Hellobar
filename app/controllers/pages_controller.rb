class PagesController < ApplicationController
  before_action :require_no_user

  layout 'static'

  def index
    redirect_to new_user_session_path
  end

  def logout_confirmation
  end
end
