describe ProfitwellGateway do
  let(:gateway) { ProfitwellGateway.new }

  before do
    allow(Settings).to receive(:profitwell_api_key).and_return('profitwell_api_key')
  end

  describe '#create_subscription' do
    let(:owner) { create :user }
    let(:subscription) { create :subscription }

    let(:request_body) do
      {
        'user_alias' => owner.id,
        'subscription_alias' => subscription.site_id,
        'email' => owner.email,
        'plan_id' => subscription.type,
        'plan_interval' => 'month',
        'plan_currency' => 'usd',
        'status' => 'active',
        'value' => subscription.amount,
        'effective_date' => subscription.created_at.to_i
      }
    end

    let!(:request) do
      stub_request(:post, 'https://api.profitwell.com/v2/subscriptions/')
        .with(
          body: request_body,
          headers: {
            'Authorization' => 'profitwell_api_key',
            'Content-Type' => 'application/json'
          }
        )
    end

    it 'sends a POST request to /subscriptions/' do
      gateway.create_subscription owner, subscription
      expect(request).to have_been_requested
    end
  end

  describe '#update_subscription' do
    let(:subscription) { create :subscription }

    let(:request_body) do
      {
        'subscription_alias' => subscription.site_id,
        'plan_id' => subscription.type,
        'plan_interval' => 'month',
        'value' => subscription.amount,
        'effective_date' => subscription.created_at.to_i
      }
    end

    let!(:request) do
      stub_request(:put, "https://api.profitwell.com/v2/subscriptions/#{ subscription.site_id }")
        .with(
          body: request_body,
          headers: {
            'Authorization' => 'profitwell_api_key',
            'Content-Type' => 'application/json'
          }
        )
    end

    it 'sends a PUT request to /subscriptions/:site_id' do
      gateway.update_subscription subscription
      expect(request).to have_been_requested
    end
  end

  describe '#churn_subscription' do
    let(:subscription) { create :subscription }

    let!(:request) do
      stub_request(
        :delete,
        "https://api.profitwell.com/v2/subscriptions/#{ subscription.site_id }/" \
        "?effective_date=#{ subscription.created_at.to_i }"
      ).with(
        headers: {
          'Authorization' => 'profitwell_api_key',
          'Content-Type' => 'application/json'
        }
      )
    end

    it 'sends a DELETE request to /subscriptions/:site_id/?effective_date=' do
      gateway.churn_subscription subscription.site_id, subscription.created_at
      expect(request).to have_been_requested
    end
  end
end
