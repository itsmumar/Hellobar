describe 'api/campaigns requests' do
  describe 'get #index' do
    let(:params) { Hash[format: :json] }

    context 'when there is no JWT token in the request headers' do
      it 'returns :unauthorized' do
        get api_campaigns_path, params

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

        get api_campaigns_path, params, headers

        expect(response).not_to be_successful
        expect(response.code).to eql '401'
      end
    end

    context 'when the JWT token is correct' do
      it 'returns campaigns for the site in the JSON format' do
        site = create :site
        user = create :user, site: site
        campaign = create :email_campaign, site: site

        headers = api_headers_for_site_user site, user

        get api_campaigns_path, { format: :json }, headers

        expect(response).to be_successful

        campaigns = json[:campaigns]

        expect(campaigns.first[:id]).to eq campaign.id
        expect(campaigns.first[:name]).to eq campaign.name
        expect(campaigns.first[:body]).to eq campaign.body
      end
    end
  end
end
