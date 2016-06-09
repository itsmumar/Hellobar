require 'integration_helper'

feature "Exit intent modal interaction", js: true do
  before do
    @user = login
  end

  after { devise_reset }


end
