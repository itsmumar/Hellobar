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

      assigns(:users).include?(sites(:zombo).owners.first).should be_true
    end

    it "finds deleted users" do
      stub_current_admin(@admin)
      user = User.create email: "test@test.com", password: 'supers3cr37'
      user.destroy
      get :index, :q => "test"

      assigns(:users).include?(user).should be_true
    end
  end

  describe "GET show" do
    before do
      stub_current_admin(@admin)
    end

    it "shows the specified user" do
      user = users(:joey)
      get :show, :id => user.id

      assigns(:user).should == user
    end

    it "shows a deleted users" do
      user = User.create email: "test@test.com", password: 'supers3cr37'
      user.destroy
      get :show, :id => user.id

      assigns(:user).should == user
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

  describe "DELETE destroy" do
    it "allows the admin to (soft) destroy a user" do
      stub_current_admin(@admin)
      user = users(:wootie)
      delete :destroy, :id => user
      User.only_deleted.should include(user)
    end
  end
end
