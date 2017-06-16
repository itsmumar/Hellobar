describe ContentUpgradesController do
  let(:user) { create(:user) }
  let(:site) { create(:site, :pro_managed) }
  let(:rule) { create(:rule, site: site) }

  before do
    stub_current_user(user)

    site.users << user
  end

  describe 'GET :index' do
    before do
      2.times { create(:content_upgrade, rule: rule) }
      get :index, site_id: site
    end

    context 'when site is not ProManaged' do
      let(:site) { create(:site) }

      it 'is forbidden' do
        expect(response.status).to eq(403)
      end
    end

    it 'works' do
      expect(response).to be_success
      expect(assigns(:content_upgrades).count).to eq(2)
    end
  end

  describe 'GET :new' do
    render_views

    it 'works' do
      get :new, site_id: site

      expect(response).to be_success
      expect(response.body).to include(user.first_name)
    end
  end

  describe 'POST :create' do
    let(:content_upgrade) { create(:content_upgrade, rule: rule) }
    let(:pdf_upload) { fixture_file_upload(content_upgrade.content_upgrade_pdf.path) }
    let(:content_upgrade_params) do
      content_upgrade.attributes.deep_symbolize_keys.merge(
        site_id: site,
        content_upgrade: { content_upgrade_pdf: pdf_upload }
      )
    end

    before { post :create, content_upgrade_params }

    it 'creates when the content upgrade' do
      expect(assigns(:content_upgrade).persisted?).to be_truthy
    end

    it 'returns a successful response' do
      expect(response).to be_redirect
    end
  end

  describe 'PUT :update' do
    let(:content_upgrade) { create(:content_upgrade, rule: rule) }
    let(:pdf_upload) { fixture_file_upload(content_upgrade.content_upgrade_pdf.path) }
    let(:content_upgrade_params) do
      content_upgrade.attributes.deep_symbolize_keys.merge(
        site_id: site,
        content_upgrade: { content_upgrade_pdf: pdf_upload }
      )
    end

    before { put :update, content_upgrade_params }

    it 'updates the content upgrade' do
      expect(assigns(:content_upgrade).persisted?).to be_truthy
    end

    it 'returns a successful response' do
      expect(response).to be_redirect
    end
  end
end
