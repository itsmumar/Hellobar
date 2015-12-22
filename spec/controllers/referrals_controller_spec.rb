require 'spec_helper'

describe ReferralsController do
  fixtures :all

  before(:each) do
    @site = sites(:zombo)
    @user = stub_current_user(@site.owners.first)
  end

  describe "GET index" do
    it "works" do
      get :index
      expect(response).to be_success
    end
  end
end
