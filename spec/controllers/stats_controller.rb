describe StatsController do
  let(:user) { create(:user) }
  let(:credit_card) { create :credit_card }
  let(:subscription) { create :subscription, :elite, credit_card: credit_card }
  let(:bill) { create :bill, grace_period_allowed: false, subscription: subscription }
  let(:service) { PayBill.new(bill) }

  before do
    stub_cyber_source(:purchase)
    service.call
  end

  describe 'GET #index' do
    before { stub_current_user(user) }
    context 'when getting a list of signups' do
      it 'should return the stats counts' do
        get 'index'
        expect(response).to be_success
        expect(assigns(:today_stats)).to eq(1)
        expect(assigns(:mtd_paid)).to eq(1)
        expect(assigns(:mtd_trials)).to eq(0)
        expect(assigns(:mtd_elite)).to eq(1)
      end
    end
  end
end
