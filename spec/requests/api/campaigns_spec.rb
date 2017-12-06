describe 'api/campaigns requests' do
  let(:site) { create :site }
  let(:user) { create :user, site: site }
  let(:headers) { api_headers_for_site_user site, user }

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
        campaign = create :email_campaign, site: site

        get api_campaigns_path, { format: :json }, headers

        expect(response).to be_successful

        campaigns = json[:campaigns]

        expect(campaigns.first[:id]).to eq campaign.id
        expect(campaigns.first[:name]).to eq campaign.name
        expect(campaigns.first[:body]).to eq campaign.body
        expect(campaigns.first[:contact_list]).to be_present
      end
    end
  end

  describe 'get #show' do
    let!(:email_campaign) { create(:email_campaign, site: site) }

    it 'returns the campaign' do
      get api_campaign_path(email_campaign), { format: :json }, headers

      expect(response).to be_successful
      expect(json[:contact_list]).to be_present
    end
  end

  describe 'post #create' do
    let(:contact_list) { create :contact_list }

    let(:email_campaign) do
      attributes_for(:email_campaign, contact_list_id: contact_list.id)
    end

    let(:params) do
      {
        email_campaign: email_campaign,
        format: :json
      }
    end

    it 'returns newly created campaign' do
      post api_campaigns_path, params, headers

      expect(response).to be_successful
      expect(json).to include email_campaign.except(:contact_list_id)
      expect(json[:contact_list]).to be_present
    end

    context 'with invalid params' do
      let(:params) do
        { email_campaign: { name: 'Name' }, format: :json }
      end

      it 'returns errors JSON' do
        post api_campaigns_path, params, headers

        expect(response).not_to be_successful
        expect(json[:errors]).to be_present
      end
    end
  end

  describe 'put #update' do
    let(:email_campaign) { create(:email_campaign, site: site) }

    let(:params) do
      {
        email_campaign: { name: 'Updated' },
        format: :json
      }
    end

    it 'returns updated campaign' do
      put api_campaign_path(email_campaign), params, headers

      expect(response).to be_successful
      expect(json).to include(name: 'Updated')
    end

    context 'with invalid params' do
      let(:params) do
        { email_campaign: { name: '' }, format: :json }
      end

      it 'returns errors JSON' do
        put api_campaign_path(email_campaign), params, headers

        expect(response).not_to be_successful
        expect(json[:errors]).to be_present
      end
    end
  end
end
