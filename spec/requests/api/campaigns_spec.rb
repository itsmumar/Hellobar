describe 'api/campaigns requests' do
  let(:site) { create :site }
  let(:user) { create :user, site: site }
  let(:headers) { api_headers_for_site_user site, user }

  let(:statistics) do
    {
      'opened' => 1,
      'rejected' => 1,
      'delivered' => 1,
      'processed' => 1,
      'sent' => 1,
      'id' => 1,
      'type' => 'campaigns'
    }
  end

  before do
    allow_any_instance_of(DynamoDB).to receive(:query).and_return([statistics])
  end

  describe 'get #index' do
    let(:params) { Hash[format: :json] }

    it 'returns campaigns for the site in the JSON format' do
      campaign = create :campaign, site: site

      get api_campaigns_path, { format: :json }, headers

      expect(response).to be_successful

      campaigns = json[:campaigns]

      expect(campaigns.first[:id]).to eq campaign.id
      expect(campaigns.first[:name]).to eq campaign.name
      expect(campaigns.first[:body]).to eq campaign.body
      expect(campaigns.first[:contact_list]).to be_present
      expect(campaigns.first[:statistics]).to eql(
        'rejected' => 1,
        'sent' => 1,
        'processed' => 1,
        'deferred' => 0,
        'dropped' => 0,
        'delivered' => 1,
        'bounced' => 0,
        'opened' => 1,
        'clicked' => 0,
        'unsubscribed' => 0,
        'reported' => 0,
        'group_unsubscribed' => 0,
        'group_resubscribed' => 0,
        'type' => 'campaigns',
        'id' => 1
      )
    end

    include_examples 'JWT authentication' do
      let(:url) { api_campaigns_path }
    end
  end

  describe 'get #show' do
    let!(:campaign) { create(:campaign, site: site) }

    it 'returns the campaign' do
      get api_campaign_path(campaign), { format: :json }, headers

      expect(response).to be_successful
      expect(json[:contact_list]).to be_present
      expect(json[:statistics]).to be_present
    end
  end

  describe 'post #create' do
    let(:contact_list) { create :contact_list }

    let(:campaign) do
      attributes_for(:campaign, contact_list_id: contact_list.id)
    end

    let(:params) do
      {
        campaign: campaign,
        format: :json
      }
    end

    it 'returns newly created campaign' do
      post api_campaigns_path, params, headers

      expect(response).to be_successful
      expect(json).to include campaign.except(:contact_list_id)
      expect(json[:contact_list]).to be_present
    end

    context 'with invalid params' do
      let(:params) do
        { campaign: { name: 'Name' }, format: :json }
      end

      it 'returns errors JSON' do
        post api_campaigns_path, params, headers

        expect(response).not_to be_successful
        expect(json[:errors]).to be_present
      end
    end
  end

  describe 'put #update' do
    let(:campaign) { create(:campaign, site: site) }

    let(:params) do
      {
        campaign: { name: 'Updated' },
        format: :json
      }
    end

    it 'returns updated campaign' do
      put api_campaign_path(campaign), params, headers

      expect(response).to be_successful
      expect(json).to include(name: 'Updated')
    end

    context 'with invalid params' do
      let(:params) do
        { campaign: { name: '' }, format: :json }
      end

      it 'returns errors JSON' do
        put api_campaign_path(campaign), params, headers

        expect(response).not_to be_successful
        expect(json[:errors]).to be_present
      end
    end
  end

  describe 'post #send_out' do
    let(:campaign) { create(:campaign, site: site) }

    it 'responds with success' do
      post send_out_api_campaign_path(campaign), { format: :json }, headers

      expect(response).to be_successful
      expect(json).to include(message: 'Campaign successfully sent.')
    end

    it 'calls SendCampaign service' do
      expect(SendCampaign).to receive_service_call.with(campaign)

      post send_out_api_campaign_path(campaign), { format: :json }, headers
    end
  end

  describe 'post #send_test_email' do
    let!(:campaign) { create(:campaign, site: site) }
    let(:contacts) { [{ email: 'email@example.com', name: 'Name' }] }
    let(:params) { Hash[contacts: contacts, format: :json] }

    it 'calls SendTestEmailForCampaign service' do
      expect(SendTestEmailForCampaign).to receive_service_call.with(campaign, contacts)
      post send_out_test_email_api_campaign_path(campaign), params, headers
      expect(response).to be_successful
      expect(json).to include(message: 'Test email successfully sent.')
    end
  end
end
