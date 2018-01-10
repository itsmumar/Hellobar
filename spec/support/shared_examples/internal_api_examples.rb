shared_examples 'Token authentication' do
  # expects `request` is defined

  context 'when there is no Authorization token in the request headers' do
    let(:headers) { nil }

    it 'returns :unauthorized' do
      request
      expect(response).not_to be_successful
      expect(response.code).to eql '401'
    end
  end
end
