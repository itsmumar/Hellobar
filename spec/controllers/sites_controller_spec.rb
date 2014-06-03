require 'spec_helper'

describe SitesController do
  fixtures :all

  before(:each) do
    @user = users(:joey)
  end

  describe "POST create" do
    it "allows a logged-in user to create a new site and sets him as the owner" do
      stub_user(@user)

      lambda {
        post :create, :site => {:url => "zombo.com"}
      }.should change(@user.sites, :count).by(1)

      site = @user.sites.last

      site.url.should == "zombo.com"
      @user.role_for_site(site).should == :owner
    end
  end
end
