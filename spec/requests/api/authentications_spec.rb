describe 'api/authentications requests' do
  describe 'GET #create' do
    context 'when not logged in' do
      it 'redirects to the root path' do
        get(api_authenticate_path)

        expect(response.status).to be 403
      end
    end

    context 'when logged in' do
      let(:site) { create :site }
      let(:user) { create :user, site: site }
      let(:params) { { format: :json } }
      let(:headers) { api_headers_for_user(user) }
      let(:token) { JsonWebToken.encode(user_id: user.id) }

      before do
        login_as user, scope: :user, run_callbacks: false
      end

      it 'redirects to callback url with token and site_id in query params' do
        expect(FetchContactListTotals).to receive_service_call.and_return({})

        get(api_authenticate_path)

        expect(json[:email]).to eql user.email
        expect(json[:first_name]).to eql user.first_name
        expect(json[:last_name]).to eql user.last_name
        expect(json[:site_id]).to eql site.id
        expect(json[:sites]).to be_present
        expect(json[:token]).to eql token
      end
    end
  end
end
