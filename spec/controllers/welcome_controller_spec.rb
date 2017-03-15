require 'spec_helper'

describe WelcomeController, '#index' do
  it 'redirects a logged in user to their dashboard' do
    site = create(:site, :with_user)
    user = site.owners.first

    controller.stub current_user: user

    get :index

    response.should redirect_to(site_path(site))
  end

  it 'does not redirect a new user' do
    get :index

    response.should be_success
  end
end
