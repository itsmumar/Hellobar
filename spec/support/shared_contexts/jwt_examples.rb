shared_examples 'JWT authentication' do
  let(:params) { Hash[format: :json] }

  context 'when there is no JWT token in the request headers' do
    it 'returns :unauthorized' do
      get url, params

      expect(response).not_to be_successful
      expect(response.code).to eql '401'
    end
  end

  context 'when the JWT token cannot be decoded' do
    it 'returns :unauthorized' do
      # token generated for user_id: 1, site_id: 1 in development environment
      # (using different secret, making it invalid)
      token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJzaXRlX2lkIjoxfQ.2GwzO9nJ8ajnpN_AZfsNgrFsCox9VaM6GfCsoUCy6Ys'
      headers = Hash['Authorization' => "Bearer #{ token }"]

      get url, params, headers

      expect(response).not_to be_successful
      expect(response.code).to eql '401'
    end
  end
end
