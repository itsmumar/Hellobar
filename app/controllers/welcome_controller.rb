class WelcomeController < ApplicationController
  layout 'static'

  before_action :require_no_user, only: :index

  def index
    @button_text = get_ab_variation("Homepage: Button")
  end
end
