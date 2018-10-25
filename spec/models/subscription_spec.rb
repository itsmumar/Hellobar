describe Subscription do
  it { is_expected.to validate_presence_of :schedule }
  it { is_expected.to validate_presence_of :site }

  it 'soft-deletes when object is being destroyed', :freeze do
    subscription = create :subscription
    subscription.destroy

    expect(subscription.reload).to be_deleted
    expect(subscription.deleted_at).to eq Time.current
  end

  describe '.pro_or_growth_for' do
    context 'when user signed up before 2018-04-01' do
      let(:user) { build :user, created_at: '2018-03-31' }

      it 'returns Pro' do
        expect(Subscription.pro_or_growth_for(user)).to be Subscription::Pro
      end
    end

    context 'when user signed up after 2018-04-01' do
      let(:user) { build :user, created_at: '2018-04-01' }

      it 'returns Growth' do
        expect(Subscription.pro_or_growth_for(user)).to be Subscription::Growth
      end
    end
  end

  describe '.paid scope' do
    let!(:paid_subscription) { create(:subscription, :pro) }
    let!(:unpaid_subscription) { create(:subscription, :pro) }

    before do
      create(:bill, :pending, subscription: unpaid_subscription)
    end

    context 'when today is between bill start and end date' do
      it 'returns paid subscriptions with paid bills' do
        create(:bill, :paid, subscription: paid_subscription)
        expect(Subscription.paid).to match_array [paid_subscription]
      end
    end

    context 'when bill is outdated' do
      it 'returns no subscriptions' do
        create(:bill, :paid, subscription: paid_subscription, start_date: 1.month.ago, end_date: 1.day.ago)
        expect(Subscription.paid).to be_empty
      end
    end
  end

  describe '.active_until' do
    it 'gets the max date that the subscription is paid till' do
      end_date = 4.weeks.from_now
      first_bill = create(:bill, status: :paid, start_date: 1.week.ago, end_date: 1.week.from_now)
      create(:bill, status: :paid, start_date: 1.week.ago, end_date: end_date, subscription: first_bill.subscription)
      expect(first_bill.subscription.active_until).to be_within(1.second).of(end_date)
    end

    it 'returns nil when there are no paid bills' do
      bill = create(:bill, status: :pending, start_date: 1.week.ago, end_date: 1.week.from_now)
      expect(bill.subscription.active_until).to be(nil)
    end
  end

  describe '.days_left' do
    it 'returns number of days before active subscription ends' do
      end_date = 4.weeks.from_now
      first_bill = create(:bill, status: :paid, start_date: 1.week.ago, end_date: 1.week.from_now)
      create(:bill, status: :paid, start_date: 1.week.ago, end_date: end_date, subscription: first_bill.subscription)
      days_left = (end_date.to_date - Date.current).to_i

      expect(first_bill.subscription.days_left).to eql days_left
    end
  end

  describe '.estimated_price' do
    before { allow_any_instance_of(DiscountCalculator).to receive(:current_discount).and_return(12) }
    before { allow_any_instance_of(Subscription).to receive(:amount).and_return(13) }

    it 'returns discounted price' do
      expect(Subscription.estimated_price(double(:user), :monthly)).to eql 1
      expect(Subscription.estimated_price(double(:user), :yearly)).to eql 1
    end

    context 'without a user' do
      it 'returns the regular price' do
        expect(Subscription.estimated_price(nil, :yearly)).to eql 1
      end
    end
  end

  describe '#monthly? / #yearly?' do
    specify 'monthly subscriptions are monthly' do
      subscription = build_stubbed :subscription, :monthly

      expect(subscription).to be_monthly
      expect(subscription).not_to be_yearly
    end

    specify 'yearly subscriptions are yearly' do
      subscription = build_stubbed :subscription, :yearly

      expect(subscription).not_to be_monthly
      expect(subscription).to be_yearly
    end
  end

  describe '#period' do
    context 'when monthly' do
      let(:subscription) { build(:subscription, schedule: 'monthly') }

      specify 'returns 1.month when monthly' do
        expect(subscription.period).to eql 1.month
      end
    end

    context 'when yearly' do
      let(:subscription) { build(:subscription, schedule: 'yearly') }

      specify 'returns 1.year when monthly' do
        expect(subscription.period).to eql 1.year
      end
    end
  end

  describe '#trial_period' do
    context 'when subscription is a trial' do
      let(:subscription) { create(:subscription, trial_end_date: 1.week.from_now) }

      specify 'returns the difference between trial end date and created_at' do
        expect(subscription.trial_period).to eql 1.week
      end
    end

    context 'when subscription is not a trial' do
      let(:subscription) { build(:subscription, trial_end_date: nil) }

      specify 'returns nil' do
        expect(subscription.trial_period).to be_nil
      end
    end
  end

  describe '#initialize' do
    let(:site) { create :site, subscription_type }
    let(:subscription) { site.active_subscription }

    context 'by default' do
      let(:subscription) { Subscription.new }

      it 'sets monthly schedule' do
        expect(subscription).to be_monthly
      end
    end

    context 'Free' do
      let(:subscription_type) { :free }

      it 'sets initial values' do
        expect(subscription.amount).to eql 0
        expect(subscription.visit_overage).to eql 5000
        expect(subscription.visit_overage_unit).to eql nil
        expect(subscription.visit_overage_amount).to eql nil

        expect(site.views_limit).to eql 5000
      end
    end

    context 'FreePlus' do
      let(:subscription_type) { :free_plus }

      it 'sets initial values' do
        expect(subscription.amount).to eql 0
        expect(subscription.visit_overage).to eql 5000
        expect(subscription.visit_overage_unit).to eql nil
        expect(subscription.visit_overage_amount).to eql nil

        expect(site.views_limit).to eql 5000
      end
    end

    context 'Pro' do
      let(:subscription_type) { :pro }

      it 'sets initial values' do
        expect(subscription.amount).to eql 29
        expect(subscription.visit_overage).to eql 50_000
        expect(subscription.visit_overage_unit).to eql nil
        expect(subscription.visit_overage_amount).to eql 5

        expect(site.views_limit).to eql 50_000
      end

      context 'when yearly' do
        let(:subscription) { build :subscription, :pro, schedule: 'yearly' }

        specify { expect(subscription.amount).to eql 289 }
      end
    end

    context 'Growth' do
      let(:subscription_type) { :growth }

      it 'sets initial values' do
        expect(subscription.amount).to eql 29
        expect(subscription.visit_overage).to eql 50_000
        expect(subscription.visit_overage_unit).to eql nil
        expect(subscription.visit_overage_amount).to eql 5

        expect(site.views_limit).to eql 50_000
      end

      context 'when yearly' do
        let(:subscription) { build :subscription, :growth, schedule: 'yearly' }

        specify { expect(subscription.amount).to eql 289 }
      end
    end

    context 'ProSpecial' do
      let(:subscription_type) { :pro_special }

      it 'sets initial values' do
        expect(subscription.amount).to eql 29
        expect(subscription.visit_overage).to eql 50_000
        expect(subscription.visit_overage_unit).to eql nil
        expect(subscription.visit_overage_amount).to eql 5

        expect(site.views_limit).to eql 50_000
      end

      context 'when yearly' do
        let(:subscription) { build :subscription, :pro_special, schedule: 'yearly' }

        specify { expect(subscription.amount).to eql 149 }
      end
    end

    context 'Custom0' do
      let(:subscription_type) { :custom_0 }

      it 'sets initial values' do
        expect(subscription.amount).to eql 149
        expect(subscription.visit_overage).to eql 2_000_000
        expect(subscription.visit_overage_unit).to eql nil
        expect(subscription.visit_overage_amount).to eql 5

        expect(site.views_limit).to eql 2_000_000
      end

      context 'when yearly' do
        let(:subscription) { build :subscription, :custom_0, schedule: 'yearly' }

        specify { expect(subscription.amount).to eql 1490 }
      end
    end

    context 'Custom1' do
      let(:subscription_type) { :custom_1 }

      it 'sets initial values' do
        expect(subscription.amount).to eql 199
        expect(subscription.visit_overage).to eql 5_000_000
        expect(subscription.visit_overage_unit).to eql nil
        expect(subscription.visit_overage_amount).to eql 5

        expect(site.views_limit).to eql 5_000_000
      end

      context 'when yearly' do
        let(:subscription) { build :subscription, :custom_1, schedule: 'yearly' }

        specify { expect(subscription.amount).to eql 1990 }
      end
    end

    context 'Custom2' do
      let(:subscription_type) { :custom_2 }

      it 'sets initial values' do
        expect(subscription.amount).to eql 299
        expect(subscription.visit_overage).to eql 10_000_000
        expect(subscription.visit_overage_unit).to eql nil
        expect(subscription.visit_overage_amount).to eql 5

        expect(site.views_limit).to eql 10_000_000
      end

      context 'when yearly' do
        let(:subscription) { build :subscription, :custom_2, schedule: 'yearly' }

        specify { expect(subscription.amount).to eql 2990 }
      end
    end

    context 'Custom3' do
      let(:subscription_type) { :custom_3 }

      it 'sets initial values' do
        expect(subscription.amount).to eql 399
        expect(subscription.visit_overage).to eql 20_000_000
        expect(subscription.visit_overage_unit).to eql nil
        expect(subscription.visit_overage_amount).to eql 5

        expect(site.views_limit).to eql 20_000_000
      end

      context 'when yearly' do
        let(:subscription) { build :subscription, :custom_3, schedule: 'yearly' }

        specify { expect(subscription.amount).to eql 3990 }
      end
    end

    context 'ProComped' do
      let(:subscription_type) { :pro_comped }

      it 'sets initial values' do
        expect(subscription.amount).to eql 0
        expect(subscription.visit_overage).to eql nil
        expect(subscription.visit_overage_unit).to eql nil
        expect(subscription.visit_overage_amount).to eql 0

        expect(site.views_limit).to eql ::Float::INFINITY
      end
    end

    context 'ProManaged' do
      let(:subscription_type) { :pro_managed }

      it 'sets initial values' do
        expect(subscription.amount).to eql 0
        expect(subscription.visit_overage).to eql nil
        expect(subscription.visit_overage_unit).to eql nil
        expect(subscription.visit_overage_amount).to eql nil

        expect(site.views_limit).to eql ::Float::INFINITY
      end
    end

    context 'EliteSpecial' do
      let(:subscription_type) { :elite_special }

      it 'sets initial values' do
        expect(subscription.amount).to eql 99
        expect(subscription.visit_overage).to eql 500_000
        expect(subscription.visit_overage_unit).to eql nil
        expect(subscription.visit_overage_amount).to eql 5

        expect(site.views_limit).to eql 500_000
      end

      context 'when yearly' do
        let(:subscription) { build :subscription, :elite_special, schedule: 'yearly' }

        specify { expect(subscription.amount).to eql 799 }
      end
    end

    context 'Elite' do
      let(:subscription_type) { :elite }

      it 'sets initial values' do
        expect(subscription.amount).to eql 99
        expect(subscription.visit_overage).to eql 500_000
        expect(subscription.visit_overage_unit).to eql nil
        expect(subscription.visit_overage_amount).to eql 5
      end

      context 'when yearly' do
        let(:subscription) { build :subscription, :elite, schedule: 'yearly' }

        specify { expect(subscription.amount).to eql 999 }
      end
    end
  end

  describe '#currently_on_trial?' do
    let(:bill) { create(:bill, :pro, :paid) }

    context 'when subscription amount is not 0 and has a paid bill but no credit card' do
      before do
        bill.update_attribute(:amount, 0)
        bill.subscription.credit_card = nil
      end

      specify { expect(bill.subscription).to be_currently_on_trial }
    end

    context 'when subscription amount is not 0 and paid bill is not 0' do
      specify { expect(bill.subscription).not_to be_currently_on_trial }
    end

    context 'when there are no paid bills' do
      specify { expect(create(:subscription)).not_to be_currently_on_trial }
    end
  end

  describe 'problem_with_payment?' do
    context 'bill is past due' do
      let!(:bill) { create(:past_due_bill) }

      specify { expect(bill.subscription).to be_problem_with_payment }
    end

    context 'all bills are paid' do
      let!(:bill) { create(:bill, :pro, :paid) }

      specify { expect(bill.subscription).not_to be_problem_with_payment }
    end
  end

  describe '#expired?' do
    context 'when pro' do
      let!(:bill) { create(:bill, :pro, :paid) }

      specify { expect(bill.subscription).not_to be_expired }

      context 'and period has ended', :freeze do
        specify do
          Timecop.travel(1.month.from_now + 1.day) do
            expect(bill.subscription).to be_expired
          end
        end
      end

      context 'and not paid' do
        let!(:bill) { create(:bill, :pro) }

        specify { expect(bill.subscription).to be_expired }
      end
    end

    context 'when free' do
      let!(:bill) { create(:bill) }

      specify { expect(bill.subscription).not_to be_expired }

      context 'and period has ended' do
        specify do
          Timecop.travel(1.year.from_now) do
            expect(bill.subscription).not_to be_expired
          end
        end
      end
    end
  end

  describe '#active_bills' do
    let!(:subscription) { create(:subscription, :with_bills) }

    before { Bill.delete_all }

    it 'returns all bills active for time period', :freeze do
      expect(subscription.active_bills).to be_empty

      # Add a bill after
      create(:bill, subscription: subscription, start_date: 15.days.from_now, end_date: 45.days.from_now, amount: 1)
      expect(subscription.active_bills).to be_empty

      # Add a bill before
      create(:bill, subscription: subscription, start_date: 45.days.ago, end_date: 15.days.ago, amount: 1)
      expect(subscription.active_bills).to be_empty

      # Add a bill during time, but void
      create(:bill, :voided, subscription: subscription, start_date: Time.current, end_date: 30.days.from_now, amount: 1)
      expect(subscription.active_bills).to be_empty

      # Add an active bill
      bill = create(:bill, subscription: subscription, start_date: Time.current, end_date: 30.days.from_now, amount: 1)
      expect(subscription.reload.active_bills).to match_array [bill]
    end
  end
end
