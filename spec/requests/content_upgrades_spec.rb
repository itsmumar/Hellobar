require 'integration_helper'

describe 'Content upgrade requests' do
  let(:user) { create :user }
  let(:site) { create :site, :with_rule, user: user }
  let!(:subscription) { create :subscription, :pro_managed, user: user, site: site }

  context 'when unauthenticated' do
    describe 'GET :index' do
      it 'responds with a redirect to the login page' do
        get site_content_upgrades_path(1)

        expect(response).to be_a_redirect
        expect(response.location).to include 'sign_in'
      end
    end
  end

  context 'when authenticated' do
    let!(:content_upgrade) { create(:content_upgrade, site: site) }
    let(:pdf_upload) { fixture_file_upload(content_upgrade.content_upgrade_pdf.path) }
    let(:content_upgrade_params) do
      content_upgrade.attributes.deep_symbolize_keys.merge(
        site_id: site,
        content_upgrade: { content_upgrade_pdf: pdf_upload }
      )
    end

    before { login_as user, scope: :user, run_callbacks: false }

    context 'when subscription is not ProManaged' do
      let(:subscription) { create :subscription, :pro }

      describe 'GET :index' do
        it 'responds with a redirect to the root path' do
          get site_content_upgrades_path(site)

          expect(response).to be_forbidden
        end
      end
    end

    describe 'GET :index' do
      it 'responds with success' do
        get site_content_upgrades_path(site)

        expect(response).to be_successful
      end
    end

    describe 'GET :new' do
      it 'responds with success' do
        get new_site_content_upgrade_path site

        expect(response).to be_successful
      end
    end

    describe 'POST :create' do
      it 'creates a new content upgrade when params are correct' do
        expect {
          post site_content_upgrades_path(site), content_upgrade_params
        }.to change { ContentUpgrade.count }.by 1

        expect(response).to be_a_redirect
      end

      it 'does not create a new content upgrade when some params are missing' do
        params = content_upgrade_params.merge(offer_headline: '')

        expect {
          post site_content_upgrades_path(site), params
        }.not_to change { ContentUpgrade.count }

        expect(response).to be_successful
      end
    end

    describe 'GET :edit' do
      let(:content_upgrade) { create :content_upgrade, site: site }

      it 'responds with success' do
        get edit_site_content_upgrade_path site, content_upgrade

        expect(response).to be_successful
      end
    end

    describe 'PATCH :update' do
      let(:content_upgrade) { create :content_upgrade, site: site }

      it 'updates data of an existing content upgrade when params are correct' do
        params = content_upgrade_params.merge(offer_headline: 'new offer_headline')

        expect {
          patch site_content_upgrade_path(site, content_upgrade), params
        }.to change { content_upgrade.reload.offer_headline }.to params[:offer_headline]

        expect(response).to be_a_redirect
      end

      it 'does not update an content upgrade when some params are missing' do
        params = content_upgrade_params.merge(offer_headline: '')

        expect {
          patch site_content_upgrade_path(site, content_upgrade), params
        }.not_to change { content_upgrade.reload.offer_headline }

        expect(response).to be_successful
      end
    end

    describe 'POST :update_styles' do
      it 'updates site.settings[:content_upgrade]' do
        params = site.content_upgrade_styles.merge(offer_font_size: '32px', offer_font_family: 'Oswald,sans-serif')

        expect { post update_styles_site_content_upgrades_path(site), params }
          .to change { site.reload.content_upgrade_styles[:offer_font_size] }.to('32px')
          .and change { site.reload.content_upgrade_styles[:offer_font_family_name] }.to('Oswald')

        expect(response).to be_a_redirect
      end
    end

    describe 'GET :style_editor' do
      it 'responds with success' do
        get style_editor_site_content_upgrades_path(site)
        expect(response).to be_successful
      end
    end
  end
end
