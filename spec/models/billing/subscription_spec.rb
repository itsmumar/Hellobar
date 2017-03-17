require 'spec_helper'

module SubscriptionHelper
  def setup_subscriptions
    @user = create(:user)
    @site = create(:site)
    @payment_method = create(:payment_method)
    @free = Subscription::Free.new(user: @user, site: @site)
    @pro = Subscription::Pro.new(user: @user, site: @site)
    @enterprise = Subscription::Enterprise.new(user: @user, site: @site)
    expect(@site.current_subscription).to be_nil
    expect(@site.bills).to eq([])
    expect(@free.amount).to eq(0)
    expect(@pro.amount).not_to eq(0)
    expect(@enterprise.amount).not_to eq(0)
  end
end

describe Subscription do
  include SubscriptionHelper

  describe '.estimated_price' do
    it 'returns the subscriptions monthly amount - calculated discounts' do
      allow_any_instance_of(DiscountCalculator).to receive(:current_discount).and_return(12)
      expected_result = Subscription::Pro.defaults[:monthly_amount] - 12
      expect(Subscription::Pro.estimated_price(double(:user), :monthly)).to eq(expected_result)
    end

    it 'returns the subscriptions yearly amount - calculated discounts' do
      allow_any_instance_of(DiscountCalculator).to receive(:current_discount).and_return(12)
      expected_result = Subscription::Pro.defaults[:yearly_amount] - 12
      expect(Subscription::Pro.estimated_price(double(:user), :yearly)).to eq(expected_result)
    end

    it 'returns the subscriptions price if user is nil' do
      expected_result = Subscription::Pro.defaults[:yearly_amount]
      expect(Subscription::Pro.estimated_price(nil, :yearly)).to eq(expected_result)
    end
  end

  describe '.active scope' do
    let(:pro_subscription) { create(:pro_subscription) }

    it 'includes subscriptions with paid bills at the current time' do
      bill = create(:recurring_bill, subscription: pro_subscription, start_date: 1.week.ago, end_date: 1.week.from_now, status: :paid)
      expect(Subscription.active).to include(bill.subscription)
    end

    it 'does not include unpaid bills' do
      bill = create(:recurring_bill, subscription: pro_subscription, start_date: 1.week.ago, end_date: 1.week.from_now, status: :pending)
      expect(Subscription.active).to_not include(bill.subscription)
    end

    it 'does not include bills in a different period' do
      bill = create(:recurring_bill, subscription: pro_subscription, start_date: 2.weeks.ago, end_date: 1.week.ago, status: :pending)
      expect(Subscription.active).to_not include(bill.subscription)
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

  describe 'subclassing' do
    it 'does not consider Pro to be Free' do
      sub = Subscription::Pro.new

      expect(sub).not_to be_a(Subscription::Free)
    end

    it 'does not consider Enterprise to be Free' do
      sub = Subscription::Enterprise.new

      expect(sub).not_to be_a(Subscription::Free)
    end
  end

  describe '#currently_on_trial?' do
    let(:bill) { create(:pro_bill, :paid) }

    it 'should be true if subscription amount is not 0 and has a paid bill but no payment method' do
      bill.update_attribute(:amount, 0)
      bill.subscription.payment_method = nil
      expect(bill.subscription.currently_on_trial?).to be_true
    end

    it 'should be false if subscription amount is not 0 and paid bill is not 0' do
      expect(bill.subscription.currently_on_trial?).to be_false
    end

    it 'should be false when there are no paid bills' do
      expect(create(:subscription).currently_on_trial?).to be_false
    end
  end

  describe 'problem_with_payment?' do
    context 'bill is past due' do
      let!(:bill) { create(:past_due_bill) }

      it 'returns true' do
        expect(bill.subscription.problem_with_payment?).to be(true)
      end
    end

    context 'all bills are paid' do
      let!(:bill) { create(:pro_bill, :paid) }

      it 'returns false' do
        expect(bill.subscription.problem_with_payment?).to be(false)
      end
    end
  end

  it 'should set defaults if not set' do
    expect(Subscription::Pro.create.visit_overage).to eq(Subscription::Pro.defaults[:visit_overage])
  end

  it 'should not override values set with defaults' do
    expect(Subscription::Pro.create(visit_overage: 3).visit_overage).to eq(3)
  end

  it 'should default to monthly schedule' do
    subscription = Subscription::Pro.new
    expect(subscription.monthly?).to be_true
    expect(subscription.amount).to eq(Subscription::Pro.defaults[:monthly_amount])
  end

  it 'should let you set yearly' do
    subscription = Subscription::Pro.new(schedule: 'yearly')
    expect(subscription.yearly?).to be_true
    expect(subscription.amount).to eq(Subscription::Pro.defaults[:yearly_amount])
    # Test with symbol
    subscription = Subscription::Pro.new(schedule: :yearly)
    expect(subscription.yearly?).to be_true
    expect(subscription.amount).to eq(Subscription::Pro.defaults[:yearly_amount])
  end

  it 'should raise an exception for an invalid schedule' do
    expect { Subscription::Pro.new(schedule: 'fortnightly') }.to raise_error(ArgumentError)
  end

  it 'should set the amount based on the schedule unless overridden' do
    subscription = Subscription::Pro.create
    expect(subscription.monthly?).to be_true
    expect(subscription.yearly?).to be_false
    expect(subscription.amount).to eq(Subscription::Pro.defaults[:monthly_amount])

    subscription = Subscription::Pro.create(schedule: :yearly)
    expect(subscription.yearly?).to be_true
    expect(subscription.amount).to eq(Subscription::Pro.defaults[:yearly_amount])

    subscription = Subscription::Pro.create(schedule: :yearly, amount: 2)
    expect(subscription.yearly?).to be_true
    expect(subscription.amount).to eq(2)
  end

  it 'should return its site-specific values' do
    site = create(:site)
    pro = Subscription::Pro.new site: site
    expected_values = Subscription::Pro.values_for(site).merge(schedule: 'monthly')

    expect(pro.values).to eq(expected_values)
  end

  describe Subscription::Capabilities do
    before do
      setup_subscriptions
    end

    it 'should return default capabilities for plan' do
      capabilities = @site.capabilities(true)

      expect(capabilities).to be_a Subscription::Free::Capabilities
      expect(capabilities.closable?).to be_false

      @site.change_subscription(@pro, @payment_method)

      expect(@site.capabilities(true)).to be_a Subscription::Pro::Capabilities
    end

    it 'should return ProblemWithPayment capabilities if on a paid plan and payment has not been made' do
      @site.change_subscription(@pro, create(:payment_method, :fails))
      expect(@site.capabilities(true).class).to eq(Subscription::ProblemWithPayment::Capabilities)
    end

    it 'should return the right capabilities if a payment issue has been resolved' do
      @site.change_subscription(@pro, create(:payment_method, :fails))

      expect(@site.capabilities(true).remove_branding?).to be_false
      expect(@site.capabilities(true).closable?).to be_false
      expect(@site.site_elements.all?(&:show_branding)).to be_true
      expect(@site.site_elements.all?(&:closable)).to be_true

      @site.change_subscription(@pro, create(:payment_method))

      expect(@site.capabilities(true).remove_branding?).to be_true
      expect(@site.capabilities(true).closable?).to be_true
      expect(@site.site_elements.none?(&:show_branding)).to be_true
      expect(@site.site_elements.none?(&:closable)).to be_true
    end

    it 'should return the right capabilities if payment is not due yet' do
      _, bill = @site.change_subscription(@pro, create(:payment_method, :fails))

      expect(@site.capabilities(true).class).to eq(Subscription::ProblemWithPayment::Capabilities)
      # Make the bill not due until later
      bill.bill_at += 10.days
      bill.save!
      expect(@site.capabilities(true).class).to eq(Subscription::Pro::Capabilities)
    end

    it 'should return the right capabilities based on the active period of the Bill' do
      @site.change_subscription(@enterprise, @payment_method)
      expect(@site.capabilities(true).class).to eq(Subscription::Enterprise::Capabilities)
      @site.change_subscription(@pro, @payment_method)
      # Should still be on enterprise capabilities
      expect(@site.capabilities(true).class).to eq(Subscription::Enterprise::Capabilities)
    end

    it 'should handle refund, switch, and void' do
      success, pro_bill = @site.change_subscription(@pro, @payment_method)
      expect(success).to be_true
      expect(@site.capabilities(true).class).to eq(Subscription::Pro::Capabilities)

      # Refund
      refund_bill, refund_attempt = pro_bill.refund!
      expect(refund_bill).to be_paid
      expect(refund_attempt).to be_successful
      # Should still have pro cabalities
      expect(@site.capabilities(true).class).to eq(Subscription::Pro::Capabilities)
      # Should have a pending bill for pro
      pending = @site.bills(true).reject { |b| !b.pending? }
      expect(pending.size).to eq(1)
      expect(pending.first.subscription).to be_a(Subscription::Pro)

      # Switch to Free
      success, = @site.change_subscription(@free, @payment_method)
      expect(success).to be_true
      # Should still have pro capabilities
      expect(@site.capabilities(true).class).to eq(Subscription::Pro::Capabilities)
      # Should have a pending bill for free
      pending = @site.bills(true).reject { |b| !b.pending? }
      expect(pending.size).to eq(1)
      expect(pending.first.subscription).to be_a(Subscription::Free)

      # Void the paid bill
      pro_bill.void!
      # Should not have pro capabilities
      expect(@site.capabilities(true).class).to eq(Subscription::Free::Capabilities)
      # Should still have a pending bill for free
      pending = @site.bills(true).reject { |b| !b.pending? }
      expect(pending.size).to eq(1)
      expect(pending.first.subscription).to be_a(Subscription::Free)
    end

    it 'should return the default visit_overage for the plan' do
      expect(Subscription::Pro.create.capabilities.visit_overage).to eq(Subscription::Pro.defaults[:visit_overage])
    end

    it 'should let you override the visit_overage for the plan' do
      expect(Subscription::Pro.create(visit_overage: 3).capabilities.visit_overage).to eq(3)
    end

    it 'gives the greatest capability of all current paid subscriptions' do
      # Auto pays each of these
      @site.change_subscription(@enterprise, @payment_method)
      @site.change_subscription(@pro, @payment_method)
      @site.change_subscription(@free, @payment_method)
      expect(@site.capabilities(true)).to be_a(Subscription::Enterprise::Capabilities)
    end

    it 'stays at pro capabilities until bill period is over' do
      _, bill = @site.change_subscription(@pro, @payment_method)
      bill.update_attribute(:end_date, 1.year.from_now)
      expect(@site.capabilities(true)).to be_a(Subscription::Pro::Capabilities)
      travel_to 2.years.from_now do
        expect(@site.capabilities(true)).to be_a(Subscription::Free::Capabilities)
      end
    end

    context 'Subscription::ProManaged capabilities' do
      specify 'Subscription::Free does not have ProManaged capabilities' do
        subscription = build_stubbed :subscription, :free
        capabilities = subscription.capabilities

        expect(capabilities.custom_html?).to be_false
        expect(capabilities.content_upgrades?).to be_false
        expect(capabilities.autofills?).to be_false
        expect(capabilities.geolocation_injection?).to be_false
      end

      specify 'ProManaged plan has certain custom capabilities' do
        subscription = build_stubbed :subscription, :pro_managed
        capabilities = subscription.capabilities

        expect(capabilities.custom_html?).to be_true
        expect(capabilities.content_upgrades?).to be_true
        expect(capabilities.autofills?).to be_true
        expect(capabilities.geolocation_injection?).to be_true
      end
    end

    context '#at_site_element_limit?' do
      it 'returns true when it has as many site elements as it can have' do
        expect(@site.capabilities.at_site_element_limit?).to be_false
      end

      it 'returns false when it can still add site elements' do
        max_elements = @site.capabilities.max_site_elements
        elements = ['element'] * max_elements
        @site.stub site_elements: elements

        expect(@site.capabilities.at_site_element_limit?).to be_true
      end
    end

    describe Subscription::ProblemWithPayment do
      it 'should default to Free plan capabilities' do
        expect(Subscription::ProblemWithPayment.create.capabilities.visit_overage).to eq(Subscription::Free.defaults[:visit_overage])
      end

      it 'should not let you override the visit_overage for the plan' do
        expect(Subscription::ProblemWithPayment.create(visit_overage: 3).capabilities.visit_overage).to eq(Subscription::Free.defaults[:visit_overage])
      end
    end
  end
end

describe Site do
  include SubscriptionHelper

  it 'should return Free capabilities if no subscription' do
    expect(Site.new.capabilities.class).to eq(Subscription::Free::Capabilities)
  end

  it 'should return the latest subscription capabilities otherwise' do
    s = Site.new
    s.subscriptions << Subscription::Pro.create
    expect(s.capabilities(true).class).to eq(Subscription::Pro::Capabilities)
    s.subscriptions << Subscription::Enterprise.create
    expect(s.capabilities(true).class).to eq(Subscription::Enterprise::Capabilities)
  end

  describe 'change_subscription' do
    before do
      setup_subscriptions
    end

    it 'should work with starting on a Free plan with no payment_method' do
      success, bill = @site.change_subscription(@free)
      expect(success).to be_true
      expect(bill).to be_paid
      expect(bill.amount).to eq(0)
      expect(@site.current_subscription).to eq(@free)
      expect(@site.capabilities.class).to eq(Subscription::Free::Capabilities)
    end

    it 'should work with starting out on a Free plan' do
      success, bill = @site.change_subscription(@free, @payment_method)
      expect(success).to be_true
      expect(bill).to be_paid
      expect(bill.amount).to eq(0)
      expect(@site.current_subscription).to eq(@free)
      expect(@site.capabilities.class).to eq(Subscription::Free::Capabilities)
    end

    it 'should charge a full amount for starting out a new plan for the first time' do
      success, bill = @site.change_subscription(@pro, @payment_method)
      expect(success).to be_true
      expect(bill).to be_paid
      expect(bill).to be_persisted
      expect(bill.amount).to eq(@pro.amount)
      expect(bill.bill_at).to be <= Time.now
      expect(@site.current_subscription).to eq(@pro)
      expect(@site.capabilities.class).to eq(Subscription::Pro::Capabilities)
    end

    it 'should let you preview a subscription without actually changing anything' do
      bill = @site.preview_change_subscription(@pro)
      expect(bill).not_to be_paid
      expect(bill).not_to be_persisted
      expect(bill.amount).to eq(@pro.amount)
      expect(bill.bill_at).to be <= Time.now
      expect { bill.save! }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect(bill).not_to be_persisted
      expect(@site.current_subscription).not_to eq(@pro)
      expect(@site.capabilities.class).to eq(Subscription::Free::Capabilities)
    end

    it 'should charge full amount if you were on a Free plan' do
      success, = @site.change_subscription(@free, @payment_method)
      expect(success).to be_true
      expect(@site.current_subscription).to eq(@free)
      success, bill = @site.change_subscription(@pro, @payment_method)
      expect(success).to be_true
      expect(bill).to be_paid
      expect(bill.amount).to eq(@pro.amount)
      expect(@site.current_subscription).to eq(@pro)
      expect(@site.capabilities(true).class).to eq(Subscription::Pro::Capabilities)
    end

    it 'should work to downgrade to a free plan' do
      success, pro_bill = @site.change_subscription(@pro, @payment_method)
      expect(success).to be_true
      expect(pro_bill).to be_paid
      expect(pro_bill.amount).to eq(@pro.amount)
      expect(@site.current_subscription).to eq(@pro)
      expect(@site.capabilities(true).class).to eq(Subscription::Pro::Capabilities)
      success, bill = @site.change_subscription(@free, @payment_method)
      expect(success).to be_true
      expect(bill).to be_pending
      expect(bill.amount).to eq(0)
      expect(@site.current_subscription).to eq(@free)
      # should still have pro
      expect(@site.capabilities(true).class).to eq(Subscription::Pro::Capabilities)
      # after it expires no longer have pro
      pro_bill.start_date -= 2.years
      pro_bill.end_date -= 2.years
      pro_bill.save!
      expect(@site.capabilities(true).class).to eq(Subscription::Free::Capabilities)
    end

    it 'should prorate if you are upgrading and were on a paid plan' do
      success, = @site.change_subscription(@pro, @payment_method)
      expect(success).to be_true
      expect(@site.current_subscription).to eq(@pro)
      success, bill = @site.change_subscription(@enterprise, @payment_method)
      expect(success).to be_true
      expect(bill).to be_paid
      expect(bill.amount).to eq(@enterprise.amount - @pro.amount)
      expect(@site.current_subscription).to eq(@enterprise)
      expect(@site.capabilities(true)).to be_a(Subscription::Enterprise::Capabilities)
    end

    it 'should not have prorating affected by refund' do
      success, bill1 = @site.change_subscription(@pro, @payment_method)
      expect(success).to be_true
      expect(@site.current_subscription).to eq(@pro)
      bill1.refund!
      success, bill2 = @site.change_subscription(@enterprise, @payment_method)
      expect(success).to be_true
      expect(bill2).to be_paid
      expect(bill2.amount).to eq(@enterprise.amount - @pro.amount)
      expect(@site.current_subscription).to eq(@enterprise)
      expect(@site.capabilities(true)).to be_a(Subscription::Enterprise::Capabilities)
    end

    it 'should affect prorating if you refund and switch plan' do
      success, pro_bill = @site.change_subscription(@pro, @payment_method)
      expect(success).to be_true

      # Refund
      refund_bill, refund_attempt = pro_bill.refund!
      expect(refund_bill).to be_paid
      expect(refund_attempt).to be_successful

      # Switch to Free
      success, = @site.change_subscription(@free, @payment_method)
      expect(success).to be_true

      # Switch to enterprise
      success, enterprise_bill = @site.change_subscription(@enterprise, @payment_method)
      expect(success).to be_true
      # Should still prorate
      expect(enterprise_bill.amount).to eq(@enterprise.amount - @pro.amount)
    end

    it 'should affect prorating if you refund and switch plan' do
      success, pro_bill = @site.change_subscription(@pro, @payment_method)
      expect(success).to be_true

      # Refund
      refund_bill, refund_attempt = pro_bill.refund!
      expect(refund_bill).to be_paid
      expect(refund_attempt).to be_successful

      # Switch to Free
      success, = @site.change_subscription(@free, @payment_method)
      expect(success).to be_true
      # Void the pro bill
      pro_bill.void!

      # Switch to enterprise
      success, enterprise_bill = @site.change_subscription(@enterprise, @payment_method)
      expect(success).to be_true
      # NO prorating
      expect(enterprise_bill.amount).to eq(@enterprise.amount)
    end

    it 'should prorate based on amount of time used from a paid plan' do
      success, bill = @site.change_subscription(@pro, @payment_method)
      expect(success).to be_true
      # Have used up 1/4 of bill
      one_fourth_time = (bill.end_date - bill.start_date) / 4
      bill.start_date -= one_fourth_time
      bill.end_date -= one_fourth_time
      bill.save!
      expect(@site.current_subscription).to eq(@pro)
      success, bill = @site.change_subscription(@enterprise, @payment_method)
      expect(success).to be_true
      expect(bill).to be_paid
      # Only going to apply 75% of pro payment since we used up 25% (1/4) of it
      expect(bill.amount).to eq((@enterprise.amount - @pro.amount * 0.75).to_i)
      expect(@site.current_subscription).to eq(@enterprise)
      expect(@site.capabilities(true).class).to eq(Subscription::Enterprise::Capabilities)
    end

    it 'should start your new plan after your current plan if you are downgrading' do
      success, enterprise_bill = @site.change_subscription(@enterprise, @payment_method)
      expect(success).to be_true
      expect(@site.current_subscription).to eq(@enterprise)
      success, bill = @site.change_subscription(@pro, @payment_method)
      expect(success).to be_true
      expect(bill).to be_pending
      expect(bill.amount).to eq(@pro.amount)
      expect(bill.start_date).to be_within(2.hours).of(enterprise_bill.end_date)
      expect(bill.grace_period_allowed).to be_true
      # Should still have enterprise abilities
      expect(@site.current_subscription).to eq(@pro)
      expect(@site.capabilities.class).to eq(Subscription::Enterprise::Capabilities)
    end

    it 'should charge full amount if you used to be on a paid plan but are no longer on one' do
      success, bill = @site.change_subscription(@pro, @payment_method)
      expect(success).to be_true
      expect(@site.current_subscription).to eq(@pro)
      bill.start_date = Time.now - 2.years
      bill.end_date = Time.now - 1.year
      bill.save!
      success, bill = @site.change_subscription(@enterprise, @payment_method)
      expect(success).to be_true
      expect(bill).to be_paid
      expect(bill.amount).to eq(@enterprise.amount)
      expect(@site.current_subscription).to eq(@enterprise)
      expect(@site.capabilities(true).class).to eq(Subscription::Enterprise::Capabilities)
    end

    it 'should charge full amount and void pending recurring payment if pending payment' do
      pending_bill = Bill::Recurring.create(subscription: @pro, status: :pending, amount: 25)
      expect(pending_bill).to be_pending
      success, bill = @site.change_subscription(@enterprise, @payment_method)
      expect(success).to be_true
      expect(bill).to be_paid
      expect(bill.amount).to eq(@enterprise.amount)
      expect(@site.current_subscription).to eq(@enterprise)
      expect(@site.capabilities(true).class).to eq(Subscription::Enterprise::Capabilities)
      pending_bill = Bill.find(pending_bill.id)
      expect(pending_bill).to be_voided
    end

    it 'should charge full amount and ignore pending overage payment if pending payment' do
      pending_bill = Bill::Overage.create(subscription: @pro, status: :pending, amount: 25)
      expect(pending_bill).to be_pending
      success, bill = @site.change_subscription(@enterprise, @payment_method)
      expect(success).to be_true
      expect(bill).to be_paid
      expect(bill.amount).to eq(@enterprise.amount)
      expect(@site.current_subscription).to eq(@enterprise)
      expect(@site.capabilities(true).class).to eq(Subscription::Enterprise::Capabilities)
      pending_bill = Bill.find(pending_bill.id)
      expect(pending_bill).to be_pending
    end

    it 'should return false if payment fails' do
      success, bill = @site.change_subscription(@pro, create(:payment_method, :fails))
      expect(success).to be_false
      expect(bill).to be_pending
      expect(bill.amount).to eq(@pro.amount)
      expect(@site.current_subscription).to eq(@pro)
      expect(@site.capabilities(true).class).to eq(Subscription::ProblemWithPayment::Capabilities)
    end

    it 'should not create a negative bill when switching from yearly to monthly' do
      pro_yearly = Subscription::Pro.new(user: @user, site: @site, schedule: 'yearly')
      pro_monthly = Subscription::Pro.new(user: @user, site: @site, schedule: 'monthly')

      success, bill = @site.change_subscription(pro_yearly, @payment_method)
      expect(success).to be_true
      expect(bill.amount).to eq(pro_yearly.amount)
      expect(bill).to be_paid

      success, bill2 = @site.change_subscription(pro_monthly, @payment_method)
      expect(success).to be_true
      expect(bill2.amount).to be > 0
      # Bill should be full amount
      expect(bill2.amount).to eq(pro_monthly.amount)
      # Bill should be due at end of yearly subscription
      expect(bill2.due_at).to be_within(2.hours).of(bill.due_at + 1.year)
      # Bill should be pending
      expect(bill2).to be_pending
    end
  end

  describe 'bills_with_payment_issues' do
    before do
      setup_subscriptions
    end

    it 'should return bills that are due' do
      expect(@site.bills_with_payment_issues(true)).to eq([])
      success, bill = @site.change_subscription(@pro, create(:payment_method, :fails))
      expect(success).to be_false
      expect(bill).to be_pending
      expect(@site.bills_with_payment_issues(true)).to eq([bill])
    end

    it 'should not return bills not due' do
      expect(@site.bills_with_payment_issues(true)).to eq([])
      success, bill = @site.change_subscription(@pro, create(:payment_method, :fails))
      expect(success).to be_false
      expect(bill).to be_pending
      # Make it due later
      bill.bill_at = Time.now + 7.days
      bill.save!
      expect(@site.bills_with_payment_issues(true)).to eq([])
    end

    it "should not return bills that we haven't attempted to charge at least once" do
      expect(@site.bills_with_payment_issues(true)).to eq([])
      success, bill = @site.change_subscription(@pro, create(:payment_method, :fails))
      expect(success).to be_false
      expect(bill).to be_pending
      # Delete the attempt
      # We have to do this monkey business to get around the fact that
      # BillingAttmps are read only
      BillingAttempt.connection.execute("TRUNCATE #{ BillingAttempt.table_name }")
      expect(@site.bills_with_payment_issues(true)).to eq([])
    end
  end
end
