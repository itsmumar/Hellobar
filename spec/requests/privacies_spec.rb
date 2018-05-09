describe 'Site Privacy requests' do
  let(:site) { create :site }

  context 'when unauthenticated' do
    describe 'GET #edit' do
      it 'responds with a redirect to the login page' do
        get edit_site_privacy_path site

        expect(response).to be_a_redirect
        expect(response.location).to include 'sign_in'
      end
    end
  end

  context 'when authenticated' do
    let(:user) { create :user }
    let(:site) { create :site, :installed, user: user }

    before do
      login_as user, scope: :user, run_callbacks: false
    end

    describe 'GET #edit' do
      it 'responds with success' do
        get edit_site_privacy_path site

        expect(response).to be_successful
      end
    end

    describe 'GET #update' do
      def update
        put site_privacy_path site, site: {
          communication_types: ['newsletter', 'promotional'],
          privacy_policy_url: 'http://google.com/privacy',
          terms_and_conditions_url: 'http://google.com/terms'
        }
      end

      it 'redirects to edit_site_privacy_path' do
        update
        expect(response).to redirect_to edit_site_privacy_path(site)
      end

      it 'updates site' do
        expect { update }
          .to change { site.reload.privacy_policy_url }
          .and change { site.reload.terms_and_conditions_url }

        expect(site.privacy_policy_url).to eql 'http://google.com/privacy'
        expect(site.terms_and_conditions_url).to eql 'http://google.com/terms'
      end

      it 'generates static script' do
        expect { update }
          .to have_enqueued_job(GenerateStaticScriptJob).with(site)
      end

      context 'when invalid' do
        def update
          put site_privacy_path site, site: {
            communication_types: [''],
            privacy_policy_url: ''
          }
        end

        it 'renders edit page' do
          expect { update }
            .not_to change { site.reload.updated_at }

          expect(response).to be_successful
          expect(response.body)
            .to include("Terms and conditions URL can't be blank")
            .and include("Privacy policy URL can't be blank")
            .and include("Communication types can't be blank")
        end
      end
    end
  end
end
