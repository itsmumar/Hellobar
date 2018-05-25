describe 'Content upgrade requests' do
  let(:user) { create :user }
  let(:site) { create :site, :with_rule, user: user }
  let(:site_element) { site.site_elements.last }
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
    let(:settings) { content_upgrade.content_upgrade_settings }
    let(:pdf_upload) { fixture_file_upload(settings.content_upgrade_pdf.path) }

    let(:content_upgrade_params) do
      content_upgrade.attributes.deep_symbolize_keys.slice(
        :headline,
        :caption,
        :link_text,
        :name_placeholder,
        :email_placeholder,
        :contact_list_id,
        :enable_gdpr
      )
    end

    let(:content_upgrade_settings_params) do
      settings.attributes.deep_symbolize_keys.slice(
        :offer_headline,
        :disclaimer,
        :content_upgrade_title,
        :content_upgrade_url,
        :thank_you_enabled,
        :thank_you_headline,
        :thank_you_subheading,
        :thank_you_cta,
        :thank_you_url
      ).merge(content_upgrade: { content_upgrade_pdf: pdf_upload })
    end

    let(:params) { content_upgrade_params.merge(content_upgrade_settings_params) }

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
      before do
        expect(FetchSiteStatistics)
          .to receive_service_call
          .with(site)
          .and_return(SiteStatistics.new)
      end

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
          post site_content_upgrades_path(site), params
        }.to change { ContentUpgrade.count }.by 1

        expect(response).to be_a_redirect
      end

      it 'does not create a new content upgrade when some params are missing' do
        params[:offer_headline] = ''

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
        params[:offer_headline] = 'new offer_headline'

        expect {
          patch site_content_upgrade_path(site, content_upgrade), params
        }.to change { content_upgrade.reload.offer_headline }.to params[:offer_headline]

        expect(response).to be_a_redirect
      end

      it 'does not update an content upgrade when some params are missing' do
        params[:offer_headline] = ''

        expect {
          patch site_content_upgrade_path(site, content_upgrade), params
        }.not_to change { content_upgrade.reload.offer_headline }

        expect(response).to be_successful
      end
    end

    describe 'DELETE :destroy' do
      let(:content_upgrade) { create :content_upgrade, site: site }

      it 'destroys record' do
        expect {
          delete site_content_upgrade_path(site, content_upgrade)
        }.to change(ContentUpgrade, :count).by(-1)

        expect(response).to be_a_redirect
      end
    end

    describe 'POST :update_styles' do
      let(:params) do
        {
          content_upgrade_styles: attributes_for(:content_upgrade_styles, offer_font_size: '32px', offer_font_family_name: 'Oswald')
        }
      end

      it 'updates content_upgrade_styles' do
        post update_styles_site_content_upgrades_path(site), params

        expect(site.content_upgrade_styles.offer_font_size).to eq('32px')
        expect(site.content_upgrade_styles.offer_font_family_name).to eq('Oswald')
        expect(site.content_upgrade_styles.offer_font_family).to eq('Oswald,sans-serif')

        expect(response).to be_a_redirect
      end

      it 'regenerates script' do
        expect { post update_styles_site_content_upgrades_path(site), params }
          .to have_enqueued_job(GenerateStaticScriptJob).with(site)
      end
    end

    describe 'GET :style_editor' do
      it 'responds with success' do
        get style_editor_site_content_upgrades_path(site)
        expect(response).to be_successful
      end
    end

    describe 'PUT :toggle_paused' do
      let(:content_upgrade) { create :content_upgrade, site: site }

      it 'pause content upgrade' do
        expect { put toggle_paused_site_content_upgrade_path(site, content_upgrade) }
          .to change { content_upgrade.reload.paused }.from(false).to(true)
      end

      it 'regenerates script' do
        expect {
          put toggle_paused_site_content_upgrade_path(site, content_upgrade)
        }.to have_enqueued_job(GenerateStaticScriptJob)
      end

      it 'redirects to index' do
        put toggle_paused_site_content_upgrade_path(site, content_upgrade)
        expect(response).to redirect_to site_content_upgrades_path(site)
      end

      context 'when already paused' do
        let(:content_upgrade) { create :content_upgrade, site: site, paused: true }

        it 'unpause content upgrade' do
          expect { put toggle_paused_site_content_upgrade_path(site, content_upgrade) }
            .to change { content_upgrade.reload.paused }.from(true).to(false)
        end

        it 'regenerates script' do
          expect {
            put toggle_paused_site_content_upgrade_path(site, content_upgrade)
          }.to have_enqueued_job(GenerateStaticScriptJob)
        end

        it 'redirects to index' do
          put toggle_paused_site_content_upgrade_path(site, content_upgrade)
          expect(response).to redirect_to site_content_upgrades_path(site)
        end
      end
    end
  end
end
