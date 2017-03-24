require 'spec_helper'

describe WelcomeController, '#index' do
  it 'redirects a logged in user to their dashboard' do
    site = create(:site, :with_user)
    user = site.owners.first

    stub_current_user(user)

    get :index

    expect(response).to redirect_to(site_path(site))
  end

  it 'does not redirect a new user' do
    get :index

    expect(response).to be_success
  end
end
