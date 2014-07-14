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

    it 'creates a site with a rule set' do
      stub_current_user(@user)

      mock_storage = double("asset_storage")
      mock_storage.should_receive(:create_or_update_file_with_contents)
      Hello::AssetStorage.stub(:new => mock_storage)

      post :create, :site => {:url => "zombo.com"}

      site = @user.sites.last

      site.rules.size.should == 1
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

  describe "GET preview_script" do
    it "returns a version of the site script for use in the editor live preview" do
      stub_current_user(@user)
      site = @user.sites.last

      get :preview_script, :id => site

      response.should be_success

      SiteElement::BAR_TYPES.each do |template|
        response.body.should include("HB.setTemplate(\"#{template}\"")
      end
    end
  end
end
