require 'spec_helper'

describe WelcomeController, '#index' do
  fixtures :all

  it 'redirects a logged in user to their dashboard' do
    user = users(:joey)
    site = user.sites.first

    controller.stub current_user: user

    get :index

    response.should redirect_to(site_path(site))
  end

  it 'does not redirect a new user' do
    get :index

    response.should be_success
  end
end
