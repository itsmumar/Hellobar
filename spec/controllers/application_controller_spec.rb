require 'spec_helper'

describe ApplicationController do
  fixtures :all

  describe "active_site" do
    it "returns nil if no current_user" do
      stub_user(nil)
      controller.active_site.should be_nil
    end

    it "returns current_user's first site if nothing is set in session" do
      user = stub_user(users(:joey))
      controller.active_site.should == user.sites.first
    end

    it "returns site stored in session if available" do
      user = stub_user(users(:joey))
      site = user.sites.last
      session[:active_site] = site.id

      controller.active_site.should == site
    end

    it "returns user's first site if site stored in session is not available or doesn't belong to user" do
      user = stub_user(users(:joey))
      session[:active_site] = sites(:polymathic).id

      controller.active_site.should == user.sites.first
    end

    it "returns nil if user has no sites" do
      stub_user(users(:wootie))
      controller.active_site.should be_nil
    end
  end
end
