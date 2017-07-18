describe SitesController do
  let(:user) { create(:user) }
  let(:site) { create(:site) }

  describe 'GET new' do
    before { stub_current_user(user) }

    it 'sets the site instance variable' do
      get :new

      expect(assigns[:site]).not_to be_nil
    end

    it 'sets the url if present from the params' do
      get :new, url: 'site.com'

      expect(assigns[:site].url).to eql('site.com')
    end

    it 'flashes a notice if the url is present in the params' do
      get :new, url: 'site.com'

      expect(flash[:notice]).to be_present
    end
  end

  describe 'POST create' do
    before do
      upload_to_s3 = double(:upload_to_s3, call: true)
      allow(UploadToS3).to receive(:new).and_return(upload_to_s3)
    end

    context 'when no user is logged-in' do
      it 'creates a new temporary user and logs them in' do
        expect {
          post :create, site: { url: 'temporary-site.com' }
        }.to change(User, :count).by(1)

        temp_user = User.last
        expect(temp_user.status).to eq(User::TEMPORARY_STATUS)
        expect(controller.current_user).to eq(temp_user)
      end

      it 'redirects to oauth login if oauth is set' do
        post :create, site: { url: 'temporary-sitee.com' }, oauth: true
        expect(response).to redirect_to('/auth/google_oauth2')
      end

      it 'creates a new site and sets a temporary user as the owner' do
        temp_user = User.new
        allow(User).to receive(:generate_temporary_user).and_return(temp_user)
        expect(DetectInstallType).to receive_service_call

        expect {
          post :create, site: { url: 'temporary-site.com' }
        }.to change(Site, :count).by(1)

        expect(temp_user.sites).to include(Site.last)
      end

      it "creates a new referral if a user's token is given" do
        user = User.new(email: 'temporary@email.com')
        allow(user).to receive(:temporary?).and_return(true)
        allow(User).to receive(:generate_temporary_user).and_return(user)
        expect(DetectInstallType).to receive_service_call

        expect {
          post(
            :create,
            { site: { url: 'temporary-site.com' } },
            referral_token: create(:referral_token).token
          )
        }.to change(Referral, :count).by(1)

        ref = Referral.last
        expect(ref.state).to eq('signed_up')
        expect(ref.recipient).to eq(user)
      end

      it 'updates an existing referral if its token is given' do
        ref = create(:referral, state: :sent)
        allow(User).to receive(:generate_temporary_user).and_return(user)

        expect {
          post(
            :create,
            { site: { url: 'temporary-site.com' } },
            referral_token: ref.referral_token.token
          )
        }.not_to change(Referral, :count)

        ref.reload
        expect(ref.state).to eq('signed_up')
        expect(ref.recipient).to eq(user)
      end

      it 'redirects to the editor after creation' do
        post :create, site: { url: 'temporary-site.com' }

        expect(response).to redirect_to new_site_site_element_path(Site.last)
      end

      it 'redirects to the landing page with an error if site is not valid' do
        post :create, site: { url: 'not a url lol' }

        expect(response).to redirect_to root_path
        expect(flash[:error]).to match(/not valid/)
      end

      it 'redirects to the landing page with an error if site is an email address' do
        post :create, site: { url: 'asdf@mail.com' }

        expect(response).to redirect_to root_path
        expect(flash[:error]).to match(/not valid/)
      end

      it 'creates the site with an initial free subscription' do
        post :create, site: { url: 'good-site.com' }

        site = Site.last

        expect(site.current_subscription).to be_present
        expect(site.current_subscription.is_a?(Subscription::Free)).to be_truthy
      end

      it 'redirects to login page if base URL has already been taken' do
        post :create, site: { url: "#{ site.url }/path" }, source: 'landing'

        expect(response).to redirect_to(new_user_session_path(existing_url: site.url))
      end
    end

    context 'existing user' do
      let(:user) { create(:user, :with_site) }
      let(:site) { user.sites.last }

      before { stub_current_user(user) }

      it 'can create a new site and is set as the owner' do
        expect(DetectInstallType).to receive_service_call

        expect {
          post :create, site: { url: 'newzombo.com' }
        }.to change(user.sites, :count).by(1)

        expect(site.url).to eq('http://newzombo.com')
        expect(user.role_for_site(site)).to eq(:owner)
      end

      it 'creates a site with a rule set' do
        post :create, site: { url: 'newzombo.com' }
        expect(site.rules.size).to eq(3)
      end

      it 'redirects to the editor' do
        post :create, site: { url: 'temporary-site.com' }

        expect(response).to redirect_to new_site_site_element_path(Site.last)
      end

      it 'redirects to the site when using existing url' do
        site = create(:site, url: 'www.test.com')
        site.users << user
        post :create, site: { url: 'www.test.com' }

        expect(response).to redirect_to(site_path(site))
        expect(flash[:error]).to eq('Url is already in use.')
      end
    end
  end

  describe 'put update' do
    let(:membership) { create(:site_membership) }
    let(:user) { membership.user }
    let(:site) { membership.site }

    before { stub_current_user(user) }

    it 'allows updating the url' do
      put :update, id: site.id, site: { url: 'http://updatedurl.com' }

      expect(site.reload.url).to eq('http://updatedurl.com')
    end

    it 'does not allow updating to existing urls' do
      new_membership = create(:site_membership, user: user)
      put :update, id: new_membership.site.id, site: { url: site.url }

      expect(flash[:error]).to include('URL is already in use')
    end

    it 'renders the edit template if the change was rejected' do
      allow_any_instance_of(Site).to receive(:update_attributes).and_return false
      put :update, id: site.id, site: { url: 'abc' }

      expect(subject).to render_template(:edit)
    end
  end

  describe 'GET show' do
    let(:user) { create(:user, :with_site) }
    let(:site) { user.sites.last }

    it 'sets current_site session value' do
      allow(Hello::DataAPI).to receive(:lifetime_totals).and_return(nil)
      stub_current_user(user)

      get :show, id: site

      expect(session[:current_site]).to eq(site.id)
    end
  end

  describe 'GET preview_script' do
    let(:user) { create(:user, :with_site) }
    let(:site) { user.sites.last }

    it 'renders static script' do
      stub_current_user(user)

      expect(StaticScriptAssets)
        .to receive(:render_model).with(instance_of(StaticScriptModel)).and_return('__DATA__')
      expect(StaticScriptAssets)
        .to receive(:render).with('modules.js', site_id: site.id).and_return('__MODULES__')
      expect(StaticScriptAssets)
        .to receive(:render).with('static_script_template.js', site_id: site.id).and_return('$INJECT_MODULES; $INJECT_DATA')

      get :preview_script, id: site

      expect(response).to be_success
      expect(response.body).to eql '__MODULES__; __DATA__'
    end
  end

  describe 'GET script' do
    let(:user) { create(:user, :with_site) }
    let(:site) { user.sites.last }

    it 'renders static script' do
      stub_current_user(user)

      expect(StaticScriptAssets)
        .to receive(:render_model).with(instance_of(StaticScriptModel)).and_return('__DATA__')
      expect(StaticScriptAssets)
        .to receive(:render).with('modules.js', site_id: site.id).and_return('__MODULES__')
      expect(StaticScriptAssets)
        .to receive(:render).with('static_script_template.js', site_id: site.id).and_return('$INJECT_MODULES; $INJECT_DATA')

      get :script, id: site

      expect(response).to be_success
      expect(response.body).to eql '__MODULES__; __DATA__'
    end
  end

  describe 'GET chart_data' do
    let(:site) { create(:site, :with_user, :with_rule) }
    let(:site_element) { create(:site_element, :traffic, site: site) }
    let(:user) { site.owners.first }

    before do
      stub_current_user(user)
      allow(Hello::DataAPI).to receive(:lifetime_totals).and_return(total: [[10, 1], [12, 1], [18, 2]])
    end

    it 'should return the latest lifeteime totals' do
      request.env['HTTP_ACCEPT'] = 'application/json'
      get :chart_data, id: site_element.site.id, type: :total, days: 2
      json = JSON.parse(response.body)
      expect(json.size).to eq(2)
      expect(json[0]['value']).to eq(12)
      expect(json[1]['value']).to eq(18)
    end

    it 'should return the the max amount of data if requesting more days than there is data' do
      request.env['HTTP_ACCEPT'] = 'application/json'
      get :chart_data, id: site_element.site.id, type: :total, days: 10
      json = JSON.parse(response.body)
      expect(json.size).to eq(3)
    end
  end

  describe 'PUT downgrade' do
    let(:site) { create(:site, :with_user) }
    let(:user) { site.owners.first }

    it 'downgrades a site to free' do
      stub_current_user(user)
      create(:subscription, :pro, site: site)

      put :downgrade, id: site.id

      expect(site.current_subscription).to be_a(Subscription::Free)
    end
  end

  describe 'GET install_redirect' do
    let(:site) { create(:site, :with_user) }
    let(:user) { site.owners.first }

    it 'redirects to the current sites install page' do
      stub_current_user(user)
      allow(controller).to receive(:current_site).and_return(site)

      get :install_redirect

      expect(controller).to redirect_to(site_install_path(site))
    end
  end
end
