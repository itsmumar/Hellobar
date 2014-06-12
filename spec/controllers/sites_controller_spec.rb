require 'spec_helper'

describe SitesController do
  fixtures :all

  before(:each) do
    @user = users(:joey)
  end

  describe "POST create" do
    it "allows a logged-in user to create a new site and sets him as the owner" do
      stub_current_user(@user)

      mock_storage = double("asset_storage")
      mock_storage.should_receive(:create_or_update_file_with_contents)
      Hello::AssetStorage.stub(:new => mock_storage)

      lambda {
        post :create, :site => {:url => "zombo.com"}
      }.should change(@user.sites, :count).by(1)

      site = @user.sites.last

      site.url.should == "http://zombo.com"
      @user.role_for_site(site).should == :owner
    end
  end

  describe "GET show" do
    it "sets current_site session value" do
      stub_current_user(@user)
      site = @user.sites.last

      get :show, :id => site

      session[:current_site].should == site.id
    end
  end
end
