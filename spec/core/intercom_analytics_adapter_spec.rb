describe IntercomAnalyticsAdapter do
  let!(:user) { create :user }
  let(:intercom_gateway) { instance_double(IntercomGateway) }
  let(:params) { Hash[foo: 'bar'] }
  let(:adapter) { IntercomAnalyticsAdapter.new }

  before do
    allow(IntercomGateway)
      .to receive(:new)
      .and_return intercom_gateway
  end

  describe '#track' do
    it 'sends event with IntercomGateway', :freeze do
      expect(intercom_gateway).to receive(:track).with(
        event_name: 'event',
        user_id: user.id,
        created_at: Time.current.to_i,
        metadata: params
      )

      adapter.track(
        event: 'event',
        user: user,
        params: params
      )
    end
  end
end
