require 'spec_helper'

describe ReferralsController do
  fixtures :all

  describe "GET :new" do
    render_views
    before(:each) do
      @user = stub_current_user(users(:joey))
    end

    it "works" do
      get :new

      expect(response).to be_success
      expect(response.body).to include(@user.first_name)
    end

    it "shows a link that includes the user's token" do
      get :new

      expect(response.body).to include(@user.referral_token.token)
    end
  end

  describe "GET :index" do
    before(:each) do
      @user = stub_current_user(users(:joey))
    end

    it "works" do
      2.times { create(:referral, sender: @user) }
      get :index

      expect(response).to be_success
      expect(assigns(:referrals).count).to eq(2)
    end
  end

  describe "POST :create" do
    before(:each) do
      @user = stub_current_user(users(:joey))
    end

    it "creates when an email is set" do
      post :create, {referral: {email: "kaitlen@hellobar.com"}}

      expect(assigns(:referral).persisted?).to be_true
    end

    it "does not create when an email is not set" do
      post :create, {referral: {email: ""}}

      expect(assigns(:referral).persisted?).to be_false
    end
  end

  describe "GET :accept" do
    it "sets the session variable when given a valid token" do
      get :accept, token: referral_tokens(:joey).token

      expect(response.status).to redirect_to(root_path)
      expect(session[:referral_token]).not_to be_nil
      expect(session[:referral_token]).to be(referral_tokens(:joey).token)
    end

    it "does not set the session variable when given an ivalid token" do
      get :accept, token: "wrong"

      expect(response.status).to redirect_to(root_path)
      expect(session[:referral_token]).to be_nil
    end
  end

  describe 'PUT :update' do
    before(:each) do
      @user = stub_current_user(users(:joey))
      @referral = create(:referral, state: :installed, available_to_sender: true, sender: @user)
    end

    it 'changes the site id and uses up the referral' do
      put :update, id: @referral.id, referral: {site_id: sites(:zombo).id}
      @referral.reload

      expect(@referral.site_id).to eq(sites(:zombo).id)
      expect(@referral.available_to_sender).to be_false
      expect(@referral.redeemed_by_sender_at).not_to be_nil
    end

    it 'does not change the state' do
      put :update, id: @referral.id, referral: {state: 0}
      expect(@referral.reload.state).to eq('installed')
    end
  end
end