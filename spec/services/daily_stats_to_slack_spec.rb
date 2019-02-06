describe DailyStatsToSlack, :freeze do
  let(:user) { create(:user) }
  let(:credit_card) { create :credit_card }
  let(:subscription) { create :subscription, :elite, :paid, credit_card: credit_card }
  let(:bill) { create :bill, grace_period_allowed: false, subscription: subscription }
  let(:service) { DailyStatsToSlack.new }

  before { allow(Settings).to receive(:slack_channels).and_return 'daily_stats' => 'key' }

  it 'has a message received by service' do
    Timecop.travel(1.day.from_now) do
      l = "\n\n\n\n___________________________________________________________\n___________________________________________________________\nSTATS FOR #{ Date.yesterday }:\nNew Subscriptions: 0\nChurned Subscriptions: 0\nNet New Subscriptions: 0\nTotal Paid Sites: 0\n Avg Monthly Rev Per New Site: $0\n Avg Annual Run Rate: $0\nValue of New Subs: $0\nValue Lost to Churn: $0"
      expect(PostToSlack).to receive_service_call.with(:daily_stats, text: l)

      service.call
    end
  end
end
