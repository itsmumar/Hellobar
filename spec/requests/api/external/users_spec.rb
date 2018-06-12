describe 'users API' do
  let(:user) { create(:user) }
  let(:token) { create_oauth_token(user, scopes: 'email') }

  let(:params) { {} }
  let(:headers) { { 'Authorization' => "Bearer #{ token }" } }

  describe '/me' do
    let(:request) { get(api_external_me_path(format: :json), params, headers) }

    it 'returns user email' do
      request

      expect(response).to be_successful
      expect(json[:email]).to eq user.email
    end

    include_examples 'invalid oauth token'
  end
end
