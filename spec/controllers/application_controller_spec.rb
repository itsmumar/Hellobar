require 'spec_helper'

describe ApplicationController do
  describe 'current_site' do
    let!(:current_user) { create :user, :with_site }

    it 'returns nil if no current_user' do
      stub_current_user(nil)
      controller.current_site.should be_nil
    end

    it "returns current_user's first site if nothing is set in session" do
      user = stub_current_user(current_user)
      controller.current_site.should == user.sites.first
    end

    it 'returns site stored in session if available' do
      user = stub_current_user(current_user)
      site = user.sites.last
      session[:current_site] = site.id

      controller.current_site.should == site
    end

    it "returns user's first site if site stored in session is not available or doesn't belong to user" do
      user = stub_current_user(current_user)
      session[:current_site] = create(:site).id

      controller.current_site.should == user.sites.first
    end

    context 'when user has no sites' do
      let!(:current_user) { create :user }

      it 'returns nil' do
        stub_current_user(current_user)
        controller.current_site.should be_nil
      end
    end
  end

  describe 'record_tracking_param' do
    it 'records the tracking param' do
      controller.stub(params: { trk: 'asdf' })

      Hello::TrackingParam.should_receive(:track).with('asdf')

      controller.record_tracking_param
    end
  end
end

describe ApplicationController, '#require_admin' do
  controller do
    before_action :require_admin

    def index
      render nothing: true
    end
  end

  let(:admin) { create :admin }

  it 'redirects the user to the admin login path when there is no current_admin' do
    get :index

    response.should redirect_to(admin_access_path)
  end

  it 'redirects the user to the reset password path if they need to set a new password' do
    admin.stub needs_to_set_new_password?: true
    controller.stub current_admin: admin
    controller.stub url_for: 'http://google.com'

    get :index

    response.should redirect_to(admin_reset_password_path)
  end

  it 'does not redirect if the user needs to reset their password and is currently on the page' do
    admin.stub needs_to_set_new_password?: true
    controller.stub current_admin: admin
    controller.stub url_for: admin_reset_password_path

    get :index

    response.should_not be_redirect
  end
end

describe ApplicationController, '#require_no_user' do
  controller do
    before_action :require_no_user

    def index
      render nothing: true
    end
  end

  let(:user) { create :user, :with_site }

  it 'redirects a logged in user to the dashboard of their most recent site' do
    controller.stub current_user: user
    dashboard_path = site_path(user.sites.first)

    get :index

    response.should redirect_to(dashboard_path)
  end

  it 'does not redirect a non logged in user' do
    get :index

    response.should_not be_redirect
  end
end

describe ApplicationController, '#require_pro_managed_subscription' do
  controller do
    before_action :require_pro_managed_subscription

    def index
      render nothing: true
    end
  end

  it 'redirects a user without a ProManaged subscription' do
    user = build_stubbed :user
    site = build_stubbed :site
    subscription = build_stubbed :subscription, :pro

    expect(site).to receive(:subscriptions).and_return [subscription]

    allow(controller).to receive(:current_user).and_return user
    allow(controller).to receive(:current_site).and_return site

    get :index

    expect(response).to redirect_to root_path
  end

  it 'does not redirect a user with ProManaged subscription' do
    user = build_stubbed :user
    site = build_stubbed :site
    subscription = build_stubbed :subscription, :pro_managed

    expect(site).to receive(:subscriptions).and_return [subscription]

    allow(controller).to receive(:current_user).and_return user
    allow(controller).to receive(:current_site).and_return site

    get :index

    expect(response).to be_successful
  end
end

describe ApplicationController, 'rescue_from errors' do
  controller do
    def index
      render nothing: true
    end
  end

  context 'Google::Apis::AuthorizationError' do
    it 'logs the current user out' do
      allow(controller).to receive(:index) { raise Google::Apis::AuthorizationError, 'Unauthorized' }

      expect(get(:index)).to redirect_to('/auth/google_oauth2')
    end

    it 'redirects the user to log in again to refresh the access token' do
      allow(controller).to receive(:index) { raise Google::Apis::AuthorizationError, 'Unauthorized' }

      expect(controller).to receive(:sign_out)

      get :index
    end
  end
end
