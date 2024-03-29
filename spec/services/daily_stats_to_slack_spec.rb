describe DailyStatsToSlack, :freeze do
  let(:user) { create(:user) }
  let(:site) { create :site, user: user }
  let(:credit_card) { create :credit_card, user: user }
  let(:subscription) { create :subscription, :elite, :paid, credit_card: credit_card, site: site }
  let(:bill) { create :bill, grace_period_allowed: false, subscription: subscription }
  let(:pay_service) { PayBill.new(bill) }
  let(:service) { DailyStatsToSlack.new }

  before do
    stub_cyber_source(:purchase)
    allow(Settings).to receive(:slack_channels).and_return 'daily_stats' => 'key'
    pay_service.call
  end

  it 'has a message received by service' do
    Timecop.travel(1.day.from_now) do
      l = "STATS FOR #{ Date.yesterday }:\nNew Subscriptions: 0\nChurned Subscriptions: 0\nNet New Subscriptions: 0\nTotal Paid Sites: 1\nAvg Monthly Rev Per New Site: $0\n Avg Annual Run Rate: $1,188\nValue of New Subs: $0\nValue Lost to Churn: $0"
      expect(PostToSlack).to receive_service_call.with(:daily_stats, text: l)

      service.call
    end
  end
end
