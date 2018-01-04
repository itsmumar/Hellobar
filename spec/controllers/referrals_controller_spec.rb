describe ReferralsController do
  let!(:user) { create :user }

  before do
    stub_out_ab_variations('Email Integration UI 2016-06-22') { 'original' }
    stub_current_user(user)
  end

  describe 'GET :new' do
    render_views

    it 'works' do
      get :new

      expect(response).to be_success
      expect(response.body).to include(user.first_name)
    end

    it "shows a link that includes the user's token" do
      get :new

      expect(response.body).to include(user.referral_token.token)
    end
  end

  describe 'GET :index' do
    it 'works' do
      2.times { create(:referral, sender: user) }
      get :index

      expect(response).to be_success
      expect(assigns(:referrals).count).to eq(2)
    end
  end

  describe 'POST :create' do
    it 'creates when an email is set' do
      post :create, referral: { email: 'kaitlen@hellobar.com' }

      expect(assigns(:referral).persisted?).to be_truthy
    end

    it 'does not create when an email is not set' do
      post :create, referral: { email: '' }

      expect(assigns(:referral).persisted?).to be_falsey
    end
  end

  describe 'GET :accept' do
    let(:user) { nil }
    let(:token) { 'abc123=' }
    let(:new_user) { create(:user, :temporary) }
    let(:create_user_service) { instance_double(CreateUserFromReferral) }

    before do
      allow(CreateUserFromReferral).to receive(:new).and_return(create_user_service)
    end

    context 'when user is signed in' do
      let(:user) { create(:user) }

      it 'redirects to new_site_path' do
        get :accept, token: token

        expect(response.status).to redirect_to(new_site_path)
      end
    end

    context 'when given a valid token' do
      before do
        allow(create_user_service).to receive(:call).and_return(new_user)
      end

      it 'calls CreateUserFromReferral service object' do
        expect(CreateUserFromReferral).to receive(:new).with(token)
        expect(create_user_service).to receive(:call)

        get :accept, token: token
      end

      it 'sets the session variable' do
        get :accept, token: token

        expect(session[:referral_token]).to eql(token)
      end

      it 'signs in a new user' do
        expect(controller).to receive(:sign_in).with(new_user)

        get :accept, token: token
      end

      it 'redirects to root_path' do
        get :accept, token: token

        expect(response.status).to redirect_to(root_path)
      end
    end

    context 'when given an invalid token' do
      before do
        allow(create_user_service).to receive(:call).and_raise(ActiveRecord::RecordNotFound)
      end

      it 'does not set the session variable' do
        get :accept, token: token

        expect(session[:referral_token]).to be_nil
      end

      it 'does not sign in any user' do
        expect(controller).not_to receive(:sign_in)

        get :accept, token: token
      end

      it 'redirects to root_path' do
        get :accept, token: token

        expect(response.status).to redirect_to(root_path)
      end
    end
  end

  describe 'PUT :update' do
    let!(:coupon) { create :coupon, :referral }
    let!(:site) { create :site, :free_subscription, users: [user] }
    let!(:referral) { create(:referral, state: :installed, available_to_sender: true, sender: user) }

    it 'changes the site id and uses up the referral' do
      put :update, id: referral.id, referral: { site_id: site.id }
      referral.reload

      expect(referral.site_id).to eq site.id
      expect(referral.available_to_sender).to be_falsey
      expect(referral.redeemed_by_sender_at).not_to be_nil
    end

    it 'still counts towards sites that have since been deleted' do
      site.update(deleted_at: Time.current) # simulate delete
      put :update, id: referral.id, referral: { site_id: site.id }
      referral.reload

      expect(referral.site_id).to eq site.id
      expect(referral.available_to_sender).to be_falsey
      expect(referral.redeemed_by_sender_at).not_to be_nil
    end

    it 'does not change the state' do
      put :update, id: referral.id, referral: { state: 0 }
      expect(referral.reload.state).to eq('installed')
    end
  end
end
