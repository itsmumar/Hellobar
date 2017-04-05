describe Users::OmniauthCallbacksController do
  before do
    allow(Infusionsoft).to receive(:contact_add_with_dup_check)
    allow(Infusionsoft).to receive(:contact_add_to_group)
  end

  before(:each) do
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe 'POST google_oauth2' do
    let(:send_request) { post :google_oauth2 }

    context 'when user exists' do
      let(:user) { create(:user) }
      let(:credentials) { double('credentials') }
      let(:uid) { 'abc123' }

      before do
        request.env['omniauth.auth'] = {
          'info' => { 'email' => user.email },
          'uid' => uid,
          'provider' => 'google_oauth2',
          'credentials' => credentials
        }
      end

      it 'redirects to new_site_path with a URL param' do
        session[:new_site_url] = 'www.test.com'

        send_request

        expect(response).to redirect_to(new_site_path(url: session[:new_site_url]))
      end

      context 'and has authentications' do
        let!(:authentication) { create(:authentication, user: user, uid: uid) }
        let(:credentials) { double(refresh_token: 'refresh_token', token: 'token', expires_at: Time.current.to_i) }

        it 'updates authentication tokens' do
          expect { send_request }
            .to change { authentication.reload.refresh_token }.to(credentials.refresh_token)
            .and change { authentication.reload.access_token }.to(credentials.token)
            .and change { authentication.reload.expires_at }.to(Time.at(credentials.expires_at))
        end
      end
    end

    context 'when user does not exist' do
      context 'when new_site_url session is set' do
        it 'redirects to continue_create_site_path' do
          request.env['omniauth.auth'] = {
            'info' => { 'email' => 'test@test.com' },
            'uid' => 'abc123',
            'provider' => 'google_oauth2'
          }
          session[:new_site_url] = 'www.test.com'

          send_request

          expect(response).to redirect_to(continue_create_site_path)
        end
      end

      context 'when new_site_url is not set' do
        it 'redirects to the default path' do
          request.env['omniauth.auth'] = {
            'info' => { 'email' => 'test@test.com' },
            'uid' => 'abc123',
            'provider' => 'google_oauth2'
          }

          send_request

          expect(response).to redirect_to(new_site_path)
        end
      end

      context 'when user has not been saved' do
        before do
          request.env['omniauth.auth'] = {
            'info' => { 'email' => '' },
            'uid' => 'abc123',
            'provider' => 'google_oauth2'
          }
        end

        it 'redirects to root_path' do
          send_request
          expect(response).to redirect_to(root_path)
        end

        context 'with any validation errors' do
          it 'sets flash[:error]' do
            send_request
            expect(flash[:error]).to eql 'Email can\'t be blank.'
          end

          context 'when cookie login_email exists' do
            before { cookies.permanent[:login_email] = 'some@email.com' }
            before { send_request }

            it 'removes that cookie' do
              expect(cookies[:login_email]).to be_nil
            end

            it 'sets flash[:error]' do
              expect(flash[:error]).to eql 'Please log in with your some@email.com Google email.'
            end
          end
        end

        context 'without validation errors' do
          before do
            request.env['omniauth.auth'] = {
              'info' => { 'email' => 'test@test.com' },
              'uid' => 'abc123',
              'provider' => 'google_oauth2'
            }
            user = double(persisted?: false, errors: [])
            allow(user).to receive(:save!).and_raise(StandardError)
            allow(User).to receive(:find_for_google_oauth2).and_return(user)
          end

          it 'sets flash[:error]' do
            send_request
            expect(flash[:error]).to eql 'We could not authenticate with Google.'
          end
        end
      end
    end
  end
end
