describe 'api/internal/campaigns requests' do
  let!(:campaign) { create :campaign }
  let(:token) { Settings.api_token }
  let(:headers) { Hash['Authorization' => "Token token=#{ token }"] }

  describe 'POST #update_status' do
    include_examples 'Token authentication' do
      let(:request) { post update_status_api_internal_campaign_path(1), format: :json }
    end

    let(:status) { 'sent' }
    let(:params) { Hash[campaign: { status: status }, format: :json] }

    it 'updates status and sent_at attributes', :freeze do
      post update_status_api_internal_campaign_path(campaign), params, headers

      expect(response).to be_successful
      expect(campaign.reload.status).to eq status
      expect(campaign.sent_at).to eq Time.current
    end
  end
end
