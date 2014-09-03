require 'spec_helper'

describe SitesController do
  fixtures :all

  before(:each) do
    @user = users(:joey)
  end

  describe "POST create" do
    before do
      mock_storage = double('asset_storage')
      mock_storage.should_receive(:create_or_update_file_with_contents)
      Hello::AssetStorage.stub(new: mock_storage)
    end

    context "when no user is logged-in" do
      it "creates a new temporary user and logs them in" do
        lambda {
          post :create, :site => { url: 'temporary-site.com' }
        }.should change(User, :count).by(1)

        temp_user = User.last
        temp_user.status.should == User::TEMPORARY_STATUS
        controller.current_user.should == temp_user
      end

      it "creates a new site and sets a temporary user as the owner" do
        temp_user = User.new
        User.stub(generate_temporary_user: temp_user)

        lambda {
          post :create, :site => { url: 'temporary-site.com' }
        }.should change(Site, :count).by(1)

        temp_user.sites.should include(Site.last)
      end

      it 'redirects to the editor after creation' do
        post :create, :site => { url: 'temporary-site.com' }

        response.should redirect_to new_site_site_element_path(Site.last)
      end
    end

    context "existing user" do
      before { stub_current_user(@user) }

      it "can create a new site and is set as the owner" do
        lambda {
          post :create, :site => {:url => "zombo.com"}
        }.should change(@user.sites, :count).by(1)

        site = @user.sites.last

        site.url.should == "http://zombo.com"
        @user.role_for_site(site).should == :owner
      end

      it 'creates a site with a rule set' do
        post :create, :site => {:url => "zombo.com"}

        site = @user.sites.last
        site.rules.size.should == 1
      end

      it "redirects to the site's path" do
        post :create, :site => { url: 'temporary-site.com' }

        response.should redirect_to site_path(Site.last)
      end
    end
  end

  describe "GET show" do
    it "sets current_site session value" do
      Hello::DataAPI.stub(:lifetime_totals => nil)
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
