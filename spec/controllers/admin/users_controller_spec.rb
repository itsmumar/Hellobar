require 'spec_helper'

describe Admin::UsersController do
  fixtures :all

  before(:each) do
    @admin = admins(:joey)
  end

  describe "GET index" do
    it "allows admins to search users by site URL" do
      stub_current_admin(@admin)

      get :index, :q => "zombo.com"

      assigns(:users).include?(sites(:zombo).owner).should be_true
    end
  end

  describe "POST impersonate" do
    it "allows the admin to impersonate a user" do
      stub_current_admin(@admin)

      post :impersonate, :id => users(:joey)

      controller.current_user.should == users(:joey)
    end
  end

  describe "DELETE unimpersonate" do
    it "allows the admin to stop impersonating a user" do
      stub_current_admin(@admin)

      post :impersonate, :id => users(:joey)

      controller.current_user.should == users(:joey)

      delete :unimpersonate

      controller.current_user.should be_nil
    end
  end
end
