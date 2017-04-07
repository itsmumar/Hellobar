describe Users::OmniauthCallbacksController do
  before do
    allow(Infusionsoft).to receive(:contact_add_with_dup_check)
    allow(Infusionsoft).to receive(:contact_add_to_group)
  end

  before(:each) do
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  def stub_omniauth(email: 'test@test.com', uid: 'abc123', credentials: nil)
    request.env['omniauth.auth'] = {
      'info' => { 'email' => email },
      'uid' => uid,
      'provider' => 'google_oauth2',
      'credentials' => credentials
    }
  end

  describe 'POST google_oauth2' do
    let(:send_request) { post :google_oauth2 }

    context 'when user exists' do
      let(:user) { create(:user) }
      let(:credentials) { double('credentials') }
      let(:uid) { 'abc123' }

      before do
        stub_omniauth email: user.email, uid: uid, credentials: credentials
      end

      it 'redirects to new_site_path with a URL param' do
        session[:new_site_url] = 'www.test.com'

        send_request

        expect(response).to redirect_to(new_site_path(url: session[:new_site_url]))
      end

      it 'does not create a lead' do
        expect { send_request }.not_to change(Lead, :count)
      end

      context 'and has authentications' do
        let!(:authentication) { create(:authentication, user: user, uid: uid) }
        let(:credentials) { double(refresh_token: 'refresh_token', token: 'token', expires_at: Time.current.to_i) }

        it 'updates authentication tokens' do
          expect { send_request }
            .to change { authentication.reload.refresh_token }.to(credentials.refresh_token)
            .and change { authentication.reload.access_token }.to(credentials.token)
            .and change { authentication.reload.expires_at }.to(Time.zone.at(credentials.expires_at))
        end
      end
    end

    context 'when user does not exist' do
      it 'creates a lead' do
        expect { send_request }.to change(Lead, :count).by(1)
      end

      before do
        stub_omniauth
      end

      context 'when new_site_url session is set' do
        it 'redirects to continue_create_site_path' do
          session[:new_site_url] = 'www.test.com'

          send_request

          expect(response).to redirect_to(continue_create_site_path)
        end
      end

      context 'when new_site_url is not set' do
        it 'redirects to the default path' do
          send_request

          expect(response).to redirect_to(new_site_path)
        end
      end

      context 'when user has not been saved' do
        before do
          stub_omniauth email: ''
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
            stub_omniauth
            allow(User).to receive(:find_for_google_oauth2).and_raise(ActiveRecord::ActiveRecordError)
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
