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
            expect(flash[:error]).to eql 'There was a problem connecting your Active Campaign account. Please try again later.'
          end
        end

        context 'when identity with specified provider exists' do
          before { create :identity, :active_campaign, site: site }

          it 'sets error flash message' do
            request
            expect(flash[:error]).to eql 'Please disconnect your Active Campaign before adding a new one.'
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
    end

    describe 'DELETE :destroy' do
      before { allow(ServiceProvider).to receive(:adapter).and_return(TestProvider) }

      it 'destroys an existing identity' do
        expect {
          delete site_identity_path(site, identity)
        }.to change(Identity, :count).by(-1)

        expect(response).to be_successful
      end

      context 'when identity has contact lists' do
        before { create :contact_list, identity: identity }

        it 'responds with :forbidden' do
          expect {
            delete site_identity_path(site, identity)
          }.not_to change(Identity, :count)

          expect(response).to be_forbidden
        end
      end
    end
  end
end
