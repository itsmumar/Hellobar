describe 'Identities requests' do
  let!(:site) { create :site, :with_user }
  let!(:identity) { create :identity, site: site }
  let!(:user) { site.owners.last }

  context 'when unauthenticated' do
    describe 'GET :new' do
      it 'responds with a redirect to the login page' do
        get new_site_identity_path(site)

        expect(response).to be_a_redirect
        expect(response.location).to include 'sign_in'
      end
    end
  end

  context 'when authenticated' do
    before do
      login_as user, scope: :user, run_callbacks: false
    end

    describe 'GET :new' do
      context 'without api_key param' do
        it 'redirects to /auth/:provider' do
          get new_site_identity_path(site, provider: 'active_campaign'), nil, HTTP_REFERER: 'referer'
          expect(response).to redirect_to "/auth/active_campaign/?site_id=#{ site.id }&redirect_to=referer"
        end
      end

      context 'with api_key param' do
        let(:env) { { HTTP_REFERER: '/site_elements/' } }
        let(:params) { { api_key: 'api_key', app_url: 'http://url', provider: 'active_campaign' } }

        let(:request) { get new_site_identity_path(site, params), nil, env }

        before { allow(ServiceProvider).to receive(:adapter).and_return(TestProvider) }

        it 'redirects back' do
          request
          expect(response).to redirect_to '/site_elements/#/goals'
        end

        it 'sets success flash message' do
          request
          expect(flash[:success]).to eql 'We\'ve successfully connected your Active Campaign account.'
        end

        it 'creates identity' do
          expect { request }.to change(Identity, :count).by(1)
        end

        context 'when identity is invalid' do
          before { allow(ServiceProvider).to receive(:new).and_return(double(connected?: false)) }

          it 'sets error flash message' do
            request
            expect(flash[:error]).to include 'There was a problem connecting your Active Campaign account.'
          end
        end

        context 'when identity with specified provider exists' do
          before { create :identity, :active_campaign, site: site }

          it 'sets error flash message' do
            request
            expect(flash[:error]).to include 'Please disconnect your Active Campaign account'
          end
        end
      end
    end

    describe 'GET :show' do
      before { allow(ServiceProvider).to receive(:adapter).and_return(TestProvider) }

      it 'responds with success' do
        get site_identity_path(site, id: identity.provider)
        expect(response).to be_successful
      end

      context 'when could not connect to provider' do
        before { allow_any_instance_of(TestProvider).to receive(:connected?).and_return(false) }

        it 'responds with error' do
          get site_identity_path(site, id: identity.provider)
          expect(response).to be_successful
          expect(json).to match error: true, lists: []
        end
      end
    end

    describe 'DELETE :destroy' do
      before { allow(ServiceProvider).to receive(:adapter).and_return(TestProvider) }

      context 'when identity has no contact lists' do
        it 'destroys an existing identity' do
          expect {
            delete site_identity_path(site, identity)
          }.to change(Identity, :count).by(-1)

          expect(response).to be_successful
        end
      end

      context 'when identity has an attached contact list' do
        let!(:contact_list) { create :contact_list, identity: identity }

        it 'destroys an identity and nullifies identity reference' do
          expect {
            delete site_identity_path(site, identity)
          }.to change(Identity, :count).by(-1)

          expect(response).to be_successful

          expect(contact_list.reload.identity_id).to be_nil
        end
      end

      context 'when could not destroy' do
        let!(:contact_list) { create :contact_list, identity: identity }

        it 'destroys an identity and nullifies identity reference' do
          allow_any_instance_of(Identity).to receive(:destroy).and_return(false)
          delete site_identity_path(site, identity)

          expect(response).not_to be_successful
          expect(response.status).to eql 422
        end
      end
    end

    describe 'GET :store' do
      let(:env) { Hash['HTTP_REFERER' => site_contact_lists_path(site)] }

      it 'stores onniauth data to the session' do
        OmniAuth.config.add_mock(:drip, 'credentials' => {})
        get '/auth/drip/callback', {}, env
        expect(session['omniauth_provider']).to eql OmniAuth.config.mock_auth[:drip]
      end
    end
  end
end
