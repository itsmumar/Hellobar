describe Bill do
  describe '#can_pay?' do
    subject { bill.can_pay? }
    let(:credit_card) { create :credit_card }
    let!(:bill) { create :bill, credit_card: credit_card }

    context 'without credit card' do
      let(:credit_card) { nil }

      specify { expect(subject).to be_falsey }
    end

    context 'with deleted credit card' do
      before { bill.credit_card.destroy }

      specify { expect(subject).to be_falsey }
    end

    context 'without credit card token' do
      before { bill.credit_card.update token: nil }

      specify { expect(subject).to be_falsey }
    end

    specify { expect(subject).to be_truthy }
  end

  describe '.without_refunds' do
    let!(:bill) { create :bill }
    let!(:bill_to_refund) { create :bill, :paid }

    before { stub_cyber_source :refund }

    it 'returns bills which have not been refunded' do
      RefundBill.new(bill_to_refund).call
      expect(Bill.without_refunds).not_to include bill_to_refund
    end
  end

  describe 'callbacks' do
    it 'sets the base amount before saving' do
      expect(create(:bill, amount: 10).base_amount).to eq(10)
    end
  end

  it 'should not let create a negative bill' do
    expect { Bill.create(amount: -1) }.to raise_error(Bill::InvalidBillingAmount)
  end

  it 'should not let you change the status once set' do
    bill = create(:bill, :pro)
    expect(bill.status).to eq Bill::PENDING
    bill.voided!
    expect(bill.status).to eq Bill::VOIDED
    bill.reload
    expect(bill.status).to eq Bill::VOIDED
    expect { bill.pending! }.to raise_error(Bill::StatusAlreadySet)
    expect { bill.paid! }.to raise_error(Bill::StatusAlreadySet)
    expect { bill.status = Bill::PENDING }.to raise_error(Bill::StatusAlreadySet)
  end

  it 'should record when the status was set' do
    bill = create(:bill, :pro)
    expect(bill.status).to eq Bill::PENDING
    expect(bill.status_set_at).to be_nil
    bill.paid!
    expect(bill.status_set_at).to be_within(2).of(Time.current)
  end

  it 'should take the credit_card grace period into account when grace_period_allowed' do
    now = Time.current
    bill = create(:bill, :pro, bill_at: now)
    expect(bill.grace_period_allowed?).to eq(true)
    expect(bill.bill_at).to be_within(5.minutes).of(now)
    expect(bill.due_at).to eq(bill.bill_at)
    credit_card = CreditCard.new
    expect(bill.due_at(credit_card)).to eq(bill.bill_at + credit_card.grace_period)
    bill.grace_period_allowed = false
    expect(bill.due_at(credit_card)).to eq(bill.bill_at)
  end

  describe '#during_trial_subscription?' do
    it 'should not be on trial subscription' do
      bill = create(:bill, :pro, :paid)
      expect(bill.during_trial_subscription?).to be_falsey
    end

    it 'should be on trial subscription' do
      bill = create(:bill, :pro, :paid)
      bill.update_attribute(:amount, 0)
      bill.subscription.credit_card = nil
      expect(bill.during_trial_subscription?).to be_truthy
    end
  end

  describe 'set_final_amount' do
    let!(:bill) { create(:bill, :pro, bill_at: 15.days.ago) }
    let!(:user) { create(:user) }
    let!(:coupon) { create :coupon, :referral }
    let!(:refs) do
      (1..3).map do
        create(:referral, sender: user, site: bill.site, state: 'installed', available_to_sender: true)
      end
    end

    before do
      stub_cyber_source :purchase
      bill.site.owners << user
    end

    it "sets the final amount to 0 if there's a discount for 15.0" do
      allow_any_instance_of(DiscountCalculator)
        .to receive(:current_discount).and_return(15.0)

      PayBill.new(bill).call
      expect(bill.amount).to eq(0.0)
      expect(bill.discount).to eq(15.0)
    end
  end

  describe '#calculate_discount' do
    it 'should be 0' do
      user = create(:user)
      bill = create(:bill, :pro)
      bill.site.users << user

      expect(bill.calculate_discount).to eq(0)
    end

    it 'discounts to the appropriate tier' do
      user = create(:user)
      bills =
        Array.new(35) do
          bill = create(:bill, :pro, status: :paid)
          bill.site.users << user
          user.reload
          bill.subscription.credit_card.update(user: user)
          bill.update(discount: bill.calculate_discount)
          bill
        end

      expected = []
      5.times { expected << 0 }
      5.times { expected << 2 }
      10.times { expected << 4 }
      10.times { expected << 6 }
      5.times { expected << 8 }
      expect(bills.map(&:discount)).to eq(expected)
    end
  end

  describe '#set_base_amount' do
    it 'sets the base amount from amount' do
      bill = build(:bill, amount: 10)
      expect { bill.valid? }.to change { bill.base_amount }.to eq(10)
    end

    it 'does nothing if base amount already set' do
      bill = build(:bill, amount: 10, base_amount: 12)
      expect { bill.valid? }.not_to change { bill.base_amount }.from(12)
    end
  end

  describe 'past_due' do
    context 'when pending and past due' do
      let(:bill) { create :past_due_bill }

      specify { expect(bill).to be_past_due }
    end

    context 'when past due but have not tried billing yet' do
      let(:bill) { create :past_due_bill }
      let(:credit_card) { create :credit_card }
      before { bill.billing_attempts.delete_all }

      specify { expect(bill).to be_past_due }
    end

    context 'when past due and there is no credit card' do
      let(:bill) { create :bill, :pro }
      before { bill.billing_attempts.delete_all }

      specify { expect(bill).to be_past_due }
    end
  end

  describe '#problem_reason' do
    let!(:bill) { create :past_due_bill }

    it 'returns response from CyberSource' do
      expect(bill.problem_reason).to eql 'General decline of the card'
    end
  end

  describe '#estimated_amount' do
    let!(:bill) { create :bill }
    before { allow(bill).to receive(:calculate_discount).and_return 10.0 }

    it 'returns discounted amount' do
      expect(bill.estimated_amount).to eql((bill.amount - 10).to_f)
    end
  end
end
