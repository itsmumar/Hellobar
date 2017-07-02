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
    let(:bill) { service.call }

    context 'with any refunds' do
      let(:site) { create :site, :pro }
      let!(:active_bill) { create :bill, :paid, subscription: site.current_subscription }
      let(:subscription) { create :subscription, :enterprise }

      before do
        stub_cyber_source :refund
        RefundBill.new(active_bill).call
      end

      it 'does not consider them' do
        expect(bill.amount).to eql subscription.amount
      end
    end

    context 'when upgrading' do
      let(:site) { create :site, :pro }
      let!(:active_bill) { create :bill, :paid, subscription: site.current_subscription }
      let(:subscription) { create :subscription, :enterprise }
      let!(:reduced_amount) { subscription.amount - site.current_subscription.amount }

      it 'returns bill with reduced amount' do
        expect(bill).to be_a(Bill::Recurring)
        expect(bill.amount).to eql reduced_amount
        expect(bill.grace_period_allowed).to be_falsey
        expect(bill.bill_at).to eql Time.current
        expect(bill.start_date).to eql 1.hour.ago
        expect(bill.end_date).to eql bill.start_date + subscription.period
      end

      context 'when subscription has been partially used' do
        let(:current_subscription) { site.current_subscription }

        it 'reduces amount based on used period' do
          travel_to 12.days.from_now do
            percentage_unused = 1.0 - 12.0 / Time.days_in_month(Time.current.month)
            expect(bill.amount).to eql (subscription.amount - (current_subscription.amount * percentage_unused)).to_i
          end
        end
      end
    end

    context 'when downgrading' do
      let(:site) { create :site, :enterprise }
      let!(:active_bill) { create :bill, :paid, end_date: 2.days.from_now, subscription: site.current_subscription }
      let(:subscription) { create :subscription, :pro }

      it 'returns bill with full amount' do
        expect(bill).to be_a(Bill::Recurring)
        expect(bill.amount).to eql subscription.amount
        expect(bill.grace_period_allowed).to be_truthy
        expect(bill.bill_at).to eql active_bill.end_date
        expect(bill.start_date).to eql(bill.bill_at - 1.hour)
        expect(bill.end_date).to eql bill.start_date + subscription.period
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
      expect(bill.end_date).to eql bill.start_date + subscription.period
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
