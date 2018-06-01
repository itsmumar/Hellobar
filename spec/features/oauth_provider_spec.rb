describe 'OAuth provider', :js do
  let(:user) { create(:user) }

  context 'when user signed in' do
    before do
      sign_in user
    end

    def spin_oauth_client
      Capybara::Discoball.spin(FakeOAuthClient) do |client|
        app = Doorkeeper::Application.create!({
          name: 'TestApp',
          redirect_uri: "#{ client.url }/oauth/callback",
          scopes: 'email',
          uid: FakeOAuthClient::CLIENT_ID,
          secret: FakeOAuthClient::CLIENT_SECRET
        })

        yield client
      end
    end

    it 'renders auth dialog' do
      spin_oauth_client do |client|
        visit client.url

        expect(page).to have_content('Authorize TestApp to use your account?')
        expect(page).to have_button('Authorize')
        expect(page).to have_button('Deny')
      end
    end

    it 'authenticates user' do
      spin_oauth_client do |client|
        visit client.url
        click_on 'Authorize'

        expect(page).to have_content("current_user: #{ user.email }")
      end
    end
  end
end
