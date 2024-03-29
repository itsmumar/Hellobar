describe Bill do
  specify('is pending by default') { expect(Bill.new).to be_pending }
  specify('could be paid') { expect(build(:bill, :paid)).to be_paid }
  specify('could be failed') { expect(build(:bill, :failed)).to be_failed }
  specify('could be voided') { expect(build(:bill, :voided)).to be_voided }

  describe '#credit_card_attached?' do
    subject { bill.credit_card_attached? }
    let(:credit_card) { create :credit_card }
    let(:subscription) { create(:subscription, credit_card: credit_card) }
    let!(:bill) { create :bill, subscription: subscription }

    context 'without credit card' do
      let(:credit_card) { nil }

      specify { expect(subject).to be_falsey }
    end

    context 'with deleted credit card' do
      before { bill.subscription.credit_card.destroy }

      specify { expect(subject).to be_falsey }
    end

    context 'without credit card token' do
      before { bill.subscription.credit_card.update token: nil }

      specify { expect(subject).to be_falsey }
    end

    specify { expect(subject).to be_truthy }
  end

  describe 'callbacks' do
    it 'sets the base amount before saving' do
      expect(create(:bill, amount: 10).base_amount).to eq(10)
    end
  end

  it 'should not let create a negative bill' do
    expect { Bill.create(amount: -1) }.to raise_error(Bill::InvalidBillingAmount)
  end

  describe 'state machine' do
    let(:bill) { build(:bill) }
    let(:authorization_code) { 'abc123=' }

    specify { expect(bill).to transition_from(:pending).to(:paid).on_event(:pay, authorization_code) }
    specify { expect(bill).to transition_from(:failed).to(:paid).on_event(:pay, authorization_code) }

    specify { expect(bill).to transition_from(:pending).to(:failed).on_event(:fail) }
    specify { expect(bill).to transition_from(:failed).to(:failed).on_event(:fail) }

    specify { expect(bill).to transition_from(:pending).to(:voided).on_event(:void) }
    specify { expect(bill).to transition_from(:paid).to(:voided).on_event(:void) }
    specify { expect(bill).to transition_from(:voided).to(:voided).on_event(:void) }
    specify { expect(bill).to transition_from(:failed).to(:voided).on_event(:void) }
    specify { expect(bill).to transition_from(:refunded).to(:voided).on_event(:void) }
    specify { expect(bill).to transition_from(:chargedback).to(:voided).on_event(:void) }

    specify { expect(bill).to transition_from(:paid).to(:refunded).on_event(:refund) }

    specify { expect(bill).to transition_from(:paid).to(:chargedback).on_event(:chargeback) }
  end

  it 'should record when the status was set' do
    bill = create(:bill, :pro)
    expect(bill.status_set_at).to be_nil
    bill.pay!
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

    it "sets the final amount to 0 if there's a discount for 29.0" do
      allow_any_instance_of(DiscountCalculator)
        .to receive(:current_discount).and_return(29.0)

      PayBill.new(bill).call
      expect(bill.amount).to eq(0.0)
      expect(bill.discount).to eq(29.0)
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
      5.times { expected << 4 }
      10.times { expected << 8 }
      10.times { expected << 12 }
      5.times { expected << 16 }
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

  describe '#last_billing_attempt' do
    context 'when there are several attempts' do
      let(:bill) { create(:bill, :with_attempt) }

      let!(:last_attempt) do
        create(:billing_attempt, :success, bill: bill, response: 'authorization', credit_card: bill.subscription.credit_card)
      end

      it 'returns the most recent billing attempt' do
        expect(bill.last_billing_attempt).to eq(last_attempt)
      end
    end
  end

  context 'when there is no any attempts' do
    let(:bill) { create(:bill) }

    it 'returns nil' do
      expect(bill.last_billing_attempt).to be_nil
    end
  end

  describe '#used_credit_card' do
    let(:credit_card) { create(:credit_card) }
    let(:subscription) { create(:subscription, credit_card: credit_card) }
    let(:bill) { create(:bill, subscription: subscription) }

    context 'when there is successful attempt' do
      let!(:failed_attempt) do
        create(:billing_attempt, :failed, bill: bill)
      end

      let!(:successful_attempt) do
        create(:billing_attempt, :success, bill: bill, response: 'authorization')
      end

      it 'returns credit card of that attempt' do
        expect(bill.used_credit_card).to eq(successful_attempt.credit_card)
      end
    end

    context 'when there is no successful attempt' do
      let!(:failed_attempt) do
        create(:billing_attempt, :failed, bill: bill)
      end

      let!(:failed_attempt2) do
        create(:billing_attempt, :failed, bill: bill)
      end

      it 'returns credit card of last attempt' do
        expect(bill.used_credit_card).to eq(failed_attempt2.credit_card)
      end
    end

    context 'when there is no attempts' do
      it 'returns nil' do
        expect(bill.used_credit_card).to be_nil
      end
    end
  end
end
