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
