describe 'api/campaigns requests' do
  describe 'POST #update_status' do
    context 'when unauthenticated' do
      it 'responds with :unauthorized' do
        post update_status_api_campaign_path(1), format: :json

        expect(response).to be_unauthorized
      end
    end

    context 'when authenticated' do
      let!(:campaign) { create :campaign }
      let(:token) { Settings.api_token }
      let(:status) { 'sent' }
      let(:params) { Hash[campaign: { status: status }, format: :json] }
      let(:headers) { Hash['Authorization' => "Token token=#{ token }"] }

      it 'updates status and sent_at attributes', :freeze do
        post update_status_api_campaign_path(campaign), params, headers

        expect(response).to be_successful
        expect(campaign.reload.status).to eq status
        expect(campaign.sent_at).to eq Time.current
      end
    end
  end
end
