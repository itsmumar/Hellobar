require 'spec_helper'

describe ReferralsController do
  fixtures :all

  before(:each) do
    @user = stub_current_user(users(:joey))
  end

  describe "GET index" do
    render_views

    it "works" do
      get :index
      expect(response).to be_success
      expect(response.body).to match(@user.first_name)
    end
  end

  describe "POST :create" do
    it "creates when an email is set" do
      post :create, {referral: {email: "kaitlen@hellobar.com"}}

      expect(assigns(:referral).persisted?).to be_true
    end

    it "does not create when an email is not set" do
      post :create, {referral: {email: ""}}

      expect(assigns(:referral).persisted?).to be_false
    end
  end
end
