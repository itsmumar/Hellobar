describe PendingBillPriceUpdate do
  subject!(:service) { PendingBillPriceUpdate.new(bill) }

  let!(:bill) { create(:bill, :pro, :pending) }

  context 'when bill subscription is Pro' do
    before do
      bill.update(amount: 1)
      # stub_cyber_source(:purchase)
      # ChangeSubscription.new(site, { subscription: 'pro', schedule: 'monthly' }, credit_card).call
    end

    it 'updates bill amount' do
      service.call

      expect(bill.amount).to eql(29)
    end
  end
end
