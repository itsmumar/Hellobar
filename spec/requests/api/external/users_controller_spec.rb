describe Api::External::UserController do
  let(:user) { create(:user) }
  let(:token) { create_oauth_token(user, scopes: 'email') }

  let(:params) { { format: 'json' } }
  let(:headers) { { 'Authorization' => "Bearer #{ token }" } }

  describe 'GET #show' do
    it 'returns user email' do
      get api_external_me_path, params, headers

      expect(response).to be_successful
      expect(json[:email]).to eq user.email
    end
  end
end
