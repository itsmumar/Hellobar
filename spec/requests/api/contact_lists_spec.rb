describe 'api/contact_lists requests' do
  let(:site) { create :site }
  let(:user) { create :user, site: site }
  let(:headers) { api_headers_for_site_user site, user }

  describe 'get #index' do
    let(:params) { Hash[format: :json] }

    context 'when there is no JWT token in the request headers' do
      it 'returns :unauthorized' do
        get api_contact_lists_path, params

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

        get api_contact_lists_path, params, headers

        expect(response).not_to be_successful
        expect(response.code).to eql '401'
      end
    end

    context 'when the JWT token is correct' do
      it 'returns campaigns for the site in the JSON format' do
        contact_list = create :contact_list, site: site

        get api_contact_lists_path, { format: :json }, headers

        expect(response).to be_successful

        contact_lists = json[:contact_lists]

        expect(contact_lists.first[:id]).to eq contact_list.id
        expect(contact_lists.first[:name]).to eq contact_list.name
      end
    end
  end
end
