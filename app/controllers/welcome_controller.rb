class WelcomeController < ApplicationController
  layout 'static'

  before_action :require_no_user, only: :index
end
