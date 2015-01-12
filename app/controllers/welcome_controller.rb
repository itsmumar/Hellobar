class WelcomeController < ApplicationController
  layout 'static'

  before_action :require_no_user, only: :index

  def index
    Analytics.track(*current_person_type_and_id, "Homepage")
  end
end
