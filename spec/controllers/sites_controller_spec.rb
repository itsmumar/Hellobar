describe SitesController do
  let(:user) { create(:user) }
  let(:site) { create(:site) }

  describe 'GET #new' do
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

  describe 'POST #create' do
    before do
      upload_to_s3 = double(:upload_to_s3, call: true)
      allow(UploadToS3).to receive(:new).and_return(upload_to_s3)
    end

    context 'when no user is logged-in' do
      it 'redirects to oauth login' do
        post :create, site: { url: 'temporary-site.com' }
        expect(response).to redirect_to('/auth/google_oauth2')
      end

      it 'redirects to the landing page with an error if site is not valid' do
        post :create, site: { url: 'not a valid url' }

        expect(response).to redirect_to root_path
        expect(flash[:error]).to match(/not valid/)
      end

      it 'redirects to the landing page with an error if site is an email address' do
        post :create, site: { url: 'asdf@mail.com' }

        expect(response).to redirect_to root_path
        expect(flash[:error]).to match(/not valid/)
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

      context 'when ActiveRecord::RecordInvalid is raised' do
        it 'renders errors' do
          site.errors.add :base, 'foo'
          error = ActiveRecord::RecordInvalid.new(site)
          expect(CreateSite).to receive_service_call.and_raise(error)
          post :create, site: { url: 'www.test.com' }
          expect(flash[:error]).to eq ['foo']
        end
      end

      context 'when CreateSite::DuplicateURLError is raised' do
        let!(:existing_site) { create :site, user: user, url: 'www.test.com' }

        it 'redirects to existing site' do
          post :create, site: { url: 'www.test.com' }
          expect(flash[:error]).to eq 'Url is already in use.'
          expect(response).to redirect_to site_path(existing_site)
        end
      end
    end
  end

  describe 'PUT #update' do
    let(:membership) { create(:site_membership) }
    let(:user) { membership.user }
    let(:site) { membership.site }

    before { stub_current_user(user) }

    it 'allows updating the url' do
      put :update, id: site.id, site: { url: 'http://updatedurl.com' }

      expect(site.reload.url).to eq('http://updatedurl.com')
    end

    it 'renders the edit template if the change was rejected' do
      allow_any_instance_of(Site).to receive(:update_attributes).and_return false
      put :update, id: site.id, site: { url: 'abc' }

      expect(subject).to render_template(:edit)
    end
  end

  describe 'GET #show' do
    let(:user) { create(:user, :with_site) }
    let(:site) { user.sites.last }

    it 'sets current_site session value' do
      stub_current_user(user)

      get :show, id: site

      expect(session[:current_site]).to eq(site.id)
    end
  end

  describe 'GET #preview_script' do
    let(:user) { create(:user, :with_site) }
    let(:site) { user.sites.last }

    it 'renders static script' do
      stub_current_user(user)

      expect(GenerateStaticScriptModules).to receive_service_call

      options = {
        templates: SiteElement.all_templates,
        no_rules: true,
        preview: true,
        compress: false
      }

      expect(RenderStaticScript)
        .to receive_service_call
        .with(site, options)
        .and_return('content')

      get :preview_script, id: site

      expect(response).to be_success
      expect(response.body).to eql 'content'
    end
  end

  describe 'GET #script' do
    let(:user) { create(:user, :with_site) }
    let(:site) { user.sites.last }

    it 'renders static script' do
      stub_current_user(user)

      expect(StaticScriptAssets)
        .to receive(:render_model).with(instance_of(StaticScriptModel)).and_return('__DATA__')
      expect(StaticScriptAssets)
        .to receive(:digest_path).with('modules.js').and_return('modules.js')
      expect(StaticScriptAssets)
        .to receive(:render).with('static_script_template.js', site_id: site.id).and_return('$INJECT_MODULES; $INJECT_DATA')

      get :script, id: site

      expect(response).to be_success
      expect(response.body).to eql '"/generated_scripts/modules.js"; __DATA__'
    end
  end

  describe 'GET #chart_data' do
    let(:site) { create(:site, :with_user, :with_rule) }
    let(:site_element) { create(:site_element, :traffic, site: site) }
    let(:user) { site.owners.first }
    let(:statistics) { create :site_statistics, views: [6, 10, 2], conversions: [1, 0, 1] }

    before do
      stub_current_user(user)
      expect(FetchSiteStatistics)
        .to receive_service_call.with(site, days_limit: 90).and_return(statistics)
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

  describe 'GET #improve' do
    let(:site) { create(:site, :with_user, :with_rule) }
    let(:site_element) { create(:site_element, :traffic, site: site) }
    let(:user) { site.owners.first }
    let(:statistics) { create :site_statistics, views: [6, 10, 2], conversions: [1, 0, 1] }

    before do
      stub_current_user(user)
      expect(FetchSiteStatistics)
        .to receive_service_call
        .with(site, site_element_ids: [site_element.id])
        .and_return(statistics)

      expect(FetchSiteStatistics)
        .to receive_service_call
        .with(site, days_limit: 90)
        .and_return(statistics)
    end

    it 'responds successfully' do
      get :improve, id: site_element.site.id
      expect(response).to be_success
    end
  end

  describe 'PUT #downgrade' do
    let(:site) { create(:site, :with_user) }
    let(:user) { site.owners.first }

    it 'downgrades a site to free' do
      stub_current_user(user)
      create(:subscription, :pro, site: site)

      put :downgrade, id: site.id

      expect(site.current_subscription).to be_a(Subscription::Free)
    end
  end

  describe 'GET #install_redirect' do
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
