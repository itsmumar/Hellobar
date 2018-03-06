describe 'api/campaigns requests' do
  let(:site) { create :site }
  let(:user) { create :user, site: site }
  let(:campaign) { create :campaign, :archived, site: site }
  let(:contact_list) { campaign.contact_list }

  let(:headers) { api_headers_for_user(user) }

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

  let(:recipients_count) { 3 }
  let(:recipients_response) do
    {
      DynamoDB.contacts_table_name => [
        {
          'lid' => contact_list.id,
          't' => recipients_count
        }
      ]
    }
  end

  before do
    allow_any_instance_of(DynamoDB).to receive(:query)
      .and_return([statistics])

    allow_any_instance_of(DynamoDB).to receive(:batch_get_item)
      .and_return recipients_response
  end

  describe 'GET #index' do
    let(:path) { api_site_campaigns_path(site.id, filter: 'archived') }

    include_examples 'JWT authentication' do
      def request(headers)
        get(path, { format: :json }, headers)
      end
    end

    before do
      get(path, { format: :json }, headers)
    end

    it 'returns campaigns for the site' do
      expect(response).to be_successful

      campaigns = json[:campaigns]

      expect(campaigns.first[:id]).to eq campaign.id
      expect(campaigns.first[:name]).to eq campaign.name
      expect(campaigns.first[:contact_list]).to be_present
      expect(campaigns.first[:email]).to be_present
      expect(campaigns.first[:statistics]).to eql(
        'recipients' => recipients_count,
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

    it 'returns campaigns statistics' do
      statistics = {
        total: 1,
        sent: 0,
        drafts: 0,
        archived: 1
      }

      expect(json[:statistics]).to eq statistics.deep_stringify_keys
    end
  end

  describe 'GET #show' do
    let(:path) { api_site_campaign_path(site.id, campaign) }

    include_examples 'JWT authentication' do
      def request(headers)
        get(path, { format: :json }, headers)
      end
    end

    it 'returns the campaign' do
      get(path, { format: :json }, headers)

      expect(response).to be_successful
      expect(json[:contact_list]).to be_present
      expect(json[:statistics]).to be_present
    end
  end

  describe 'POST #create' do
    let(:path) { api_site_campaigns_path(site.id) }
    let(:contact_list) { create :contact_list }
    let(:email) { create(:email) }

    let(:campaign) do
      attributes_for(:campaign, contact_list_id: contact_list.id, email_id: email.id)
    end

    let(:params) do
      {
        campaign: campaign,
        format: :json
      }
    end

    include_examples 'JWT authentication' do
      def request(headers)
        post(path, params, headers)
      end
    end

    it 'returns newly created campaign' do
      post(path, params, headers)

      expect(response).to be_successful
      expect(json).to include campaign.except(:contact_list_id)
      expect(json[:contact_list]).to be_present
    end

    context 'with invalid params' do
      let(:params) do
        { campaign: { name: 'Name' }, format: :json }
      end

      it 'returns errors JSON' do
        post(path, params, headers)

        expect(response).not_to be_successful
        expect(json[:errors]).to be_present
      end
    end
  end

  describe 'PUT #update' do
    let(:campaign) { create :campaign, :draft, site: site }
    let(:path) { api_site_campaign_path(site.id, campaign) }

    let(:params) do
      {
        campaign: { name: 'Updated' },
        format: :json
      }
    end

    include_examples 'JWT authentication' do
      def request(headers)
        put(path, params, headers)
      end
    end

    it 'returns updated campaign' do
      put(path, params, headers)

      expect(response).to be_successful
      expect(json).to include(name: 'Updated')
    end

    context 'with invalid params' do
      let(:params) do
        { campaign: { name: '' }, format: :json }
      end

      it 'returns errors JSON' do
        put(path, params, headers)

        expect(response).not_to be_successful
        expect(json[:errors]).to be_present
      end
    end
  end

  describe 'POST #send_out' do
    let(:campaign) { create :campaign, :draft, site: site }
    let(:path) { send_out_api_site_campaign_path(site.id, campaign) }

    include_examples 'JWT authentication' do
      def request(headers)
        post(path, { format: :json }, headers)
      end
    end

    it 'returns updated campaign' do
      post(path, { format: :json }, headers)

      expect(response).to be_successful
      expect(json[:status]).to eq(Campaign::SENDING)
    end

    it 'calls SendCampaign service' do
      expect(SendCampaign).to receive_service_call.with(campaign)

      post(path, { format: :json }, headers)
    end
  end

  describe 'POST #send_test_email' do
    let(:path) { send_out_test_email_api_site_campaign_path(site.id, campaign) }

    let(:contacts) { [{ email: 'email@example.com', name: 'Name' }] }
    let(:params) { Hash[contacts: contacts, format: :json] }

    include_examples 'JWT authentication' do
      def request(headers)
        post(path, params, headers)
      end
    end

    it 'calls SendTestEmailForCampaign service' do
      expect(SendTestEmailForCampaign).to receive_service_call.with(campaign, contacts)

      post(path, params, headers)

      expect(response).to be_successful
      expect(json).to include(message: 'Test email successfully sent.')
    end
  end

  describe 'POST #archive' do
    let(:path) { archive_api_site_campaign_path(site.id, campaign) }

    include_examples 'JWT authentication' do
      def request(headers)
        post(path, { format: :json }, headers)
      end
    end

    context 'when campaign can be archived' do
      before do
        campaign.sent!
      end

      it 'archives the campaign' do
        expect_any_instance_of(Campaign).to receive(:archived!)

        post(path, { format: :json }, headers)
      end

      it 'replies with success status' do
        post(path, { format: :json }, headers)

        expect(response).to be_successful
      end

      it 'returns updated campaign' do
        post(path, { format: :json }, headers)

        expect(json[:archived_at]).to be_present
      end
    end

    context 'when campaign cannot be archived' do
      it 'replies with error status' do
        post(path, { format: :json }, headers)

        expect(response).not_to be_successful
      end

      it 'returns error' do
        post(path, { format: :json }, headers)

        expect(json[:errors]).to eq([Campaign::INVALID_TRANSITION_TO_ARCHIVED])
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:path) { api_site_campaign_path(site.id, campaign) }

    let!(:campaign) { create :campaign, site: site }
    let(:params) { Hash[format: :json] }

    include_examples 'JWT authentication' do
      def request(headers)
        delete(path, params, headers)
      end
    end

    it 'calls SendTestEmailForCampaign service' do
      expect { delete(path, params, headers) }
        .to change { Campaign.count }
        .by(-1)
        .and change { Campaign.deleted.count }
        .by(1)

      expect(response).to be_successful
      expect(json).to include(message: 'Campaign successfully deleted.')
    end
  end
end
