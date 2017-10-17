describe CreateBillForNextPeriod do
  let(:service) { CreateBillForNextPeriod.new(bill) }

  context 'when bill subscription is Free' do
    let!(:bill) { create :bill, :free }

    it 'does nothing' do
      expect { service.call }
        .not_to change(Bill, :count)
    end
  end

  context 'when bill subscription is Pro' do
    let!(:bill) { create :bill, :pro }
    let(:last_bill) { Bill.last }

    it 'creates a new Bill' do
      expect { service.call }
        .to change(Bill, :count).by(1)

      expect(last_bill.subscription).to eql bill.subscription
      expect(last_bill.amount).to eql bill.subscription.amount
      expect(last_bill.grace_period_allowed).to be_truthy
      expect(last_bill.bill_at).to eql 3.days.until(bill.end_date)
      expect(last_bill.start_date).to eql bill.end_date
      expect(last_bill.end_date).to eql bill.end_date + bill.subscription.period
    end
  end
end
