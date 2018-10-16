describe CreateOverageBill do
  subject!(:service) { CreateOverageBill.new(site) }

  let(:user) { create :user }
  let(:site) { create :site, user: user, overage_count: 2 }
  let(:credit_card) { create :credit_card, user: user }
  let(:last_bill) { site.bills.last }

  context 'when bill subscription is Pro' do
    before do
      stub_cyber_source(:purchase)
      ChangeSubscription.new(site, { subscription: 'pro', schedule: 'monthly' }, credit_card).call
    end

    it 'creates a new Bill' do
      expect { service.call }
        .to change(Bill, :count).by(1)

      expect(last_bill.subscription).to eql(site.active_subscription)
      expect(last_bill.amount).to eql(10)
      expect(last_bill.grace_period_allowed).to be_truthy
      expect(last_bill.description).to eql('Monthly View Limit Overage Fee')
    end
  end
end
