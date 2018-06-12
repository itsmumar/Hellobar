shared_examples 'invalid oauth token' do
  # expects `request` and `token` are defined

  context 'when invalid token given' do
    let(:token) { 'invalid token' }

    it 'returns 401 error status' do
      request

      expect(response).not_to be_successful
      expect(response.status).to eq(401)
    end
  end

  context 'when token does not include target scope' do
    let(:token) { create_oauth_token(user, scopes: 'invalid_scope') }

    it 'returns 403 error status' do
      request

      expect(response).not_to be_successful
      expect(response.status).to eq(403)
    end
  end
end
