describe CalculateBill do
  let(:subscription) { create :subscription, :pro }
  let(:site) { create :site, :free_subscription }
  let(:service) { described_class.new(subscription, bills: site.bills) }

  context 'with pending bills' do
    let!(:pending_bill) { create :free_bill, subscription: site.current_subscription }

    it 'voids pending bills' do
      service.call
      expect(pending_bill.reload).to be_voided
    end
  end

  context 'with active paid bills', :freeze do
    context 'when upgrading' do
      let(:site) { create :site, :pro }
      let!(:active_bill) { create :bill, :paid, subscription: site.current_subscription }
      let(:subscription) { create :subscription, :enterprise }
      let(:bill) { service.call }
      let!(:reduced_amount) { subscription.amount - site.current_subscription.amount }

      it 'returns bill with full amount' do
        expect(bill).to be_a(Bill::Recurring)
        expect(bill.amount).to eql reduced_amount
        expect(bill.grace_period_allowed).to be_falsey
        expect(bill.bill_at).to eql Time.current
        expect(bill.start_date).to eql 1.hour.ago
        expect(bill.end_date).to eql bill.renewal_date
      end
    end

    context 'when downgrading' do
      let(:site) { create :site, :enterprise }
      let!(:active_bill) { create :bill, :paid, end_date: 2.days.from_now, subscription: site.current_subscription }
      let(:subscription) { create :subscription, :pro }
      let(:bill) { service.call }

      it 'returns bill with full amount' do
        expect(bill).to be_a(Bill::Recurring)
        expect(bill.amount).to eql subscription.amount
        expect(bill.grace_period_allowed).to be_truthy
        expect(bill.bill_at).to eql active_bill.end_date
        expect(bill.start_date).to eql(bill.bill_at - 1.hour)
        expect(bill.end_date).to eql bill.renewal_date
      end
    end
  end

  context 'without active paid bills', :freeze do
    let(:site) { create :site, :pro }
    let(:subscription) { create :subscription, :enterprise }
    let(:bill) { service.call }

    it 'returns bill with full amount' do
      expect(bill).to be_a(Bill::Recurring)
      expect(bill.amount).to eql subscription.amount
      expect(bill.grace_period_allowed).to be_falsey
      expect(bill.bill_at).to eql Time.current
      expect(bill.start_date).to eql 1.hour.ago
      expect(bill.end_date).to eql bill.renewal_date
    end
  end

  context 'with trial period', :freeze do
    let(:site) { create :site, :pro }
    let(:subscription) { create :subscription, :enterprise }
    let(:service) { described_class.new(subscription, bills: site.bills, trial_period: 100.days) }
    let(:bill) { service.call }

    it 'returns bill with full amount' do
      expect(bill).to be_a(Bill::Recurring)
      expect(bill.amount).to eql 0
      expect(bill.end_date).to eql Time.current + 100.days
    end
  end
end
