describe 'api/authentications requests' do
  describe 'GET #create' do
    context 'when not logged in' do
      it 'redirects to the root path' do
        get(api_authenticate_path)

        expect(response).to redirect_to(root_path)
      end
    end

    context 'when logged in' do
      it 'redirects to callback url with token and site_id in query params' do
        site = create(:site)
        user = create(:user, site: site)
        token = JsonWebToken.encode(user_id: user.id)
        callback_url = 'http://localhost'
        redirect_url = "#{ callback_url }?token=#{ token }&site_id=#{ site.id }"

        login_as user, scope: :user, run_callbacks: false

        get(api_authenticate_path, callback_url: callback_url)

        expect(response).to redirect_to(redirect_url)
      end
    end
  end
end
