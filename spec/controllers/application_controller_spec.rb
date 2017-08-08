describe ApplicationController do
  describe 'current_site' do
    let!(:current_user) { create :user, :with_site }

    it 'returns nil if no current_user' do
      stub_current_user(nil)
      expect(controller.current_site).to be_nil
    end

    it "returns current_user's first site if nothing is set in session" do
      user = stub_current_user(current_user)
      expect(controller.current_site).to eq(user.sites.first)
    end

    it 'returns site stored in session if available' do
      user = stub_current_user(current_user)
      site = user.sites.last
      session[:current_site] = site.id

      expect(controller.current_site).to eq(site)
    end

    it "returns user's first site if site stored in session is not available or doesn't belong to user" do
      user = stub_current_user(current_user)
      session[:current_site] = create(:site).id

      expect(controller.current_site).to eq(user.sites.first)
    end

    context 'when user has no sites' do
      let!(:current_user) { create :user }

      it 'returns nil' do
        stub_current_user(current_user)
        expect(controller.current_site).to be_nil
      end
    end
  end

  describe 'record_tracking_param' do
    it 'records the tracking param' do
      allow(controller).to receive(:params).and_return(trk: 'asdf')
      expect(Hello::TrackingParam).to receive(:track).with('asdf')

      controller.record_tracking_param
    end
  end
end

describe ApplicationController, '#require_no_user' do
  controller do
    before_action :require_no_user

    def index
      render nothing: true
    end
  end

  let(:user) { create :user, :with_site }

  it 'redirects a logged in user to the dashboard of their most recent site' do
    allow(controller).to receive(:current_user).and_return(user)
    dashboard_path = site_path(user.sites.first)

    get :index

    expect(response).to redirect_to(dashboard_path)
  end

  it 'does not redirect a non logged in user' do
    get :index

    expect(response).not_to be_redirect
  end
end

describe ApplicationController, '#identify_visitors' do
  controller do
    def index
      render nothing: true
    end
  end

  let(:user) { create :user, :with_site }
  let(:visitor_id) { Digest::SHA1.hexdigest(user.email) }
  let(:visitor_id_cookie) { "#{ visitor_id }#{ cookie_user_id }" }

  before do
    allow(controller).to receive(:current_user).and_return(user)

    request.cookies[Hello::InternalAnalytics::VISITOR_ID_COOKIE] = visitor_id_cookie
  end

  context 'when user is currently anonymous' do
    let(:cookie_user_id) { Hello::InternalAnalytics::USER_ID_NOT_SET_YET }

    it 'identifies logged in user' do
      expect(Analytics).to receive(:alias).with(visitor_id, user.id)

      get :index
    end
  end

  context 'when user is not anonymous' do
    let(:cookie_user_id) { user.id }

    it 'does not identify user' do
      expect(Analytics).not_to receive(:alias)

      get :index
    end
  end
end

describe ApplicationController, '#require_pro_managed_subscription' do
  controller do
    before_action :require_pro_managed_subscription

    def index
      render nothing: true
    end
  end

  it 'redirects a user without a ProManaged subscription' do
    user = build_stubbed :user
    site = build_stubbed :site
    subscription = build_stubbed :subscription, :pro

    expect(site).to receive(:subscriptions).and_return [subscription]

    allow(controller).to receive(:current_user).and_return user
    allow(controller).to receive(:current_site).and_return site

    get :index

    expect(response).to redirect_to root_path
  end

  it 'does not redirect a user with ProManaged subscription' do
    user = build_stubbed :user
    site = build_stubbed :site
    subscription = build_stubbed :subscription, :pro_managed

    expect(site).to receive(:subscriptions).and_return [subscription]

    allow(controller).to receive(:current_user).and_return user
    allow(controller).to receive(:current_site).and_return site

    get :index

    expect(response).to be_successful
  end
end

describe ApplicationController, 'current_user' do
  context 'when admin is signed in' do
    let!(:current_admin) { create :admin }

    before do
      stub_current_admin(current_admin)
    end

    context 'when session[:impersonated_user] is blank' do
      it 'returns nil' do
        session[:impersonated_user] = ''
        expect(controller.current_user).to be_nil
      end
    end

    context 'when user in session[:impersonated_user] does not exist' do
      it 'deletes session[:impersonated_user]' do
        session[:impersonated_user] = '123'
        controller.current_user
        expect(session).not_to have_key :impersonated_user
      end

      it 'returns nil' do
        expect(controller.current_user).to be_nil
      end
    end
  end

  context 'when user is signed in' do
    let!(:current_user) { create :user }

    before do
      stub_current_user(current_user)
    end

    it 'returns user' do
      expect(controller.current_user).to eql current_user
    end
  end
end
