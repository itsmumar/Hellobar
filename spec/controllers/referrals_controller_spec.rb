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
end
