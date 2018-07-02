shared_examples 'JWT authentication' do
  context 'when there is no JWT token in the request headers' do
    it 'returns :unauthorized' do
      request({})

      expect(response).not_to be_successful
      expect(response.code).to eql '401'
    end
  end

  context 'when the JWT token cannot be decoded' do
    it 'returns :unauthorized' do
      # token generated for Hash { user_id: 1 } in development environment
      # (using different secret, making it invalid)
      token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxfQ.mr8pfHgRaP5dOO8Xh9lwctUv49KU9U0W4n0Ty5V6O4A'
      headers = Hash['Authorization' => "Bearer #{ token }"]

      request headers

      expect(response).not_to be_successful
      expect(response.code).to eql '401'
    end
  end
end
