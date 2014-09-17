require 'spec_helper'

describe ApplicationController do
  fixtures :all

  describe "current_site" do
    it "returns nil if no current_user" do
      stub_current_user(nil)
      controller.current_site.should be_nil
    end

    it "returns current_user's first site if nothing is set in session" do
      user = stub_current_user(users(:joey))
      controller.current_site.should == user.sites.first
    end

    it "returns site stored in session if available" do
      user = stub_current_user(users(:joey))
      site = user.sites.last
      session[:current_site] = site.id

      controller.current_site.should == site
    end

    it "returns user's first site if site stored in session is not available or doesn't belong to user" do
      user = stub_current_user(users(:joey))
      session[:current_site] = sites(:polymathic).id

      controller.current_site.should == user.sites.first
    end

    it "returns nil if user has no sites" do
      stub_current_user(users(:wootie))
      controller.current_site.should be_nil
    end
  end

  describe "record_tracking_param" do
    it "records the tracking param" do
      controller.stub(:params => {:trk => "asdf"})

      Hello::TrackingParam.should_receive(:track).with("asdf")

      controller.record_tracking_param
    end
  end
end

describe ApplicationController, '#require_admin' do
  fixtures :all

  controller do
    before_action :require_admin

    def index; render nothing: true; end
  end

  it 'redirects the user to the root path when there is no current_admin' do
    get :index

    response.should redirect_to(root_path)
  end

  it 'redirects the user to the reset password path if they need to set a new password' do
    admin = admins(:joey)
    admin.stub needs_to_set_new_password?: true
    controller.stub current_admin: admin
    controller.stub url_for: 'http://google.com'

    get :index

    response.should redirect_to(admin_reset_password_path)
  end

  it 'does not redirect if the user needs to reset their password and is currently on the page' do
    admin = admins(:joey)
    admin.stub needs_to_set_new_password?: true
    controller.stub current_admin: admin
    controller.stub url_for: admin_reset_password_path

    get :index

    response.should_not be_redirect
  end
end

describe ApplicationController, '#require_no_user' do
  fixtures :all

  controller do
    before_action :require_no_user

    def index; render nothing: true; end
  end

  it 'redirects a logged in user to the dashboard of their most recent site' do
    user = users(:joey)
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
