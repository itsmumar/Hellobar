describe 'api/campaigns requests' do
  let!(:campaign) { create :campaign }
  let(:token) { Settings.api_token }
  let(:headers) { Hash['Authorization' => "Token token=#{ token }"] }

  describe 'POST #update_status' do
    include_examples 'Token authentication' do
      let(:request) { post update_status_api_campaign_path(1), format: :json }
    end

    let(:status) { 'sent' }
    let(:params) { Hash[campaign: { status: status }, format: :json] }

    it 'updates status and sent_at attributes', :freeze do
      post update_status_api_campaign_path(campaign), params, headers

      expect(response).to be_successful
      expect(campaign.reload.status).to eq status
      expect(campaign.sent_at).to eq Time.current
    end
  end

  describe 'POST #send_test_email' do
    include_examples 'Token authentication' do
      let(:request) { post send_test_email_api_campaign_path(1), format: :json }
    end

    let(:contacts) { [{ email: 'email@example.com', name: 'Name' }] }
    let(:params) { Hash[contacts: contacts, format: :json] }

    it 'calls SendTestEmailForCampaign service' do
      expect(SendTestEmailForCampaign).to receive_service_call.with(campaign, contacts)
      post send_test_email_api_campaign_path(campaign), params, headers
      expect(response).to be_successful
    end
  end
end
