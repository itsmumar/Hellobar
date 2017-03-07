require 'spec_helper'

module SubscriptionHelper
  def setup_subscriptions
    @user = users(:joey)
    @site = sites(:horsebike)
    @payment_method = payment_methods(:always_successful)
    @free = Subscription::Free.new(user: @user, site: @site)
    @pro = Subscription::Pro.new(user: @user, site: @site)
    @enterprise = Subscription::Enterprise.new(user: @user, site: @site)
    @site.current_subscription.should be_nil
    @site.bills.should == []
    @free.amount.should == 0
    @pro.amount.should_not == 0
    @enterprise.amount.should_not == 0
  end
end

describe Subscription do
  fixtures :all
  include SubscriptionHelper

  describe ".estimated_price" do
    it "returns the subscriptions monthly amount - calculated discounts" do
      allow_any_instance_of(DiscountCalculator).to receive(:current_discount).and_return(12)
      expected_result = Subscription::Pro.defaults[:monthly_amount] - 12
      expect(Subscription::Pro.estimated_price(double(:user), :monthly)).to eq(expected_result)
    end

    it "returns the subscriptions yearly amount - calculated discounts" do
      allow_any_instance_of(DiscountCalculator).to receive(:current_discount).and_return(12)
      expected_result = Subscription::Pro.defaults[:yearly_amount] - 12
      expect(Subscription::Pro.estimated_price(double(:user), :yearly)).to eq(expected_result)
    end

    it "returns the subscriptions price if user is nil" do
      expected_result = Subscription::Pro.defaults[:yearly_amount]
      expect(Subscription::Pro.estimated_price(nil, :yearly)).to eq(expected_result)
    end
  end

  describe ".active scope" do
    let(:pro_subscription) { create(:pro_subscription) }

    it "includes subscriptions with paid bills at the current time" do
      bill = create(:recurring_bill, subscription: pro_subscription, start_date: 1.week.ago, end_date: 1.week.from_now, status: :paid)
      expect(Subscription.active).to include(bill.subscription)
    end

    it "does not include unpaid bills" do
      bill = create(:recurring_bill, subscription: pro_subscription, start_date: 1.week.ago, end_date: 1.week.from_now, status: :pending)
      expect(Subscription.active).to_not include(bill.subscription)
    end

    it "does not include bills in a different period" do
      bill = create(:recurring_bill, subscription: pro_subscription, start_date: 2.week.ago, end_date: 1.week.ago, status: :pending)
      expect(Subscription.active).to_not include(bill.subscription)
    end
  end

  describe ".active_until" do
    it "gets the max date that the subscription is paid till" do
      end_date = 4.week.from_now
      first_bill = create(:bill, status: :paid, start_date: 1.week.ago, end_date: 1.week.from_now)
      create(:bill, status: :paid, start_date: 1.week.ago, end_date: end_date, subscription: first_bill.subscription)
      first_bill.subscription.active_until.should be_within(1.second).of(end_date)
    end

    it "returns nil when there are no paid bills" do
      bill = create(:bill, status: :pending, start_date: 1.week.ago, end_date: 1.week.from_now)
      expect(bill.subscription.active_until).to be(nil)
    end
  end

  describe "subclassing" do
    it "does not consider Pro to be Free" do
      sub = Subscription::Pro.new

      expect(sub).not_to be_a(Subscription::Free)
    end

    it "does not consider Enterprise to be Free" do
      sub = Subscription::Enterprise.new

      expect(sub).not_to be_a(Subscription::Free)
    end
  end

  describe "#currently_on_trial?" do
    it "should be true if subscription amount is not 0 and has a paid bill but no payment method" do
      bill = bills(:paid_bill)
      bill.update_attribute(:amount, 0)
      bill.subscription.payment_method = nil
      bill.subscription.currently_on_trial?.should be_true
    end

    it "should be false if subscription amount is not 0 and paid bill is not 0" do
      bill = bills(:paid_bill)
      bill.subscription.currently_on_trial?.should be_false
    end

    it "should be false when there are no paid bills" do
      subscriptions(:zombo_subscription).currently_on_trial?.should be_false
    end
  end

  describe "problem_with_payment?" do
    context "bill is past due" do
      it "returns true" do
        bill = bills(:past_due_bill)
        expect(bill.subscription.problem_with_payment?).to be(true)
      end
    end

    context "all bills are paid" do
      it "returns false" do
        bill = bills(:paid_bill)
        expect(bill.subscription.problem_with_payment?).to be(false)
      end
    end
  end

  it "should set defaults if not set" do
    Subscription::Pro.create.visit_overage.should == Subscription::Pro.defaults[:visit_overage]
  end

  it "should not override values set with defaults" do
    Subscription::Pro.create(:visit_overage=>3).visit_overage.should == 3
  end

  it "should default to monthly schedule" do
    subscription = Subscription::Pro.new
    subscription.monthly?.should be_true
    subscription.amount.should == Subscription::Pro.defaults[:monthly_amount]
  end

  it "should let you set yearly" do
    subscription = Subscription::Pro.new(schedule: "yearly")
    subscription.yearly?.should be_true
    subscription.amount.should == Subscription::Pro.defaults[:yearly_amount]
    # Test with symbol
    subscription = Subscription::Pro.new(schedule: :yearly)
    subscription.yearly?.should be_true
    subscription.amount.should == Subscription::Pro.defaults[:yearly_amount]
  end

  it "should raise an exception for an invalid schedule" do
    lambda{Subscription::Pro.new(schedule: "fortnightly")}.should raise_error(ArgumentError)
  end

  it "should set the amount based on the schedule unless overridden" do
    subscription = Subscription::Pro.create
    subscription.monthly?.should be_true
    subscription.yearly?.should be_false
    subscription.amount.should == Subscription::Pro.defaults[:monthly_amount]

    subscription = Subscription::Pro.create(:schedule=>:yearly)
    subscription.yearly?.should be_true
    subscription.amount.should == Subscription::Pro.defaults[:yearly_amount]

    subscription = Subscription::Pro.create(:schedule=>:yearly, :amount=>2)
    subscription.yearly?.should be_true
    subscription.amount.should == 2
  end

  it 'should return its site-specific values' do
    site = sites(:horsebike)
    pro = Subscription::Pro.new site: site
    expected_values = Subscription::Pro.values_for(site).merge(schedule: 'monthly')

    pro.values.should == expected_values
  end

  describe Subscription::Capabilities do
    fixtures :all

    before do
      setup_subscriptions
    end

    it "should return default capabilities for plan" do
      capabilities = @site.capabilities(true)

      expect(capabilities).to be_a Subscription::Free::Capabilities
      expect(capabilities.closable?).to be_false

      @site.change_subscription(@pro, @payment_method)

      expect(@site.capabilities(true)).to be_a Subscription::Pro::Capabilities
    end

    it "should return ProblemWithPayment capabilities if on a paid plan and payment has not been made" do
      @site.change_subscription(@pro, payment_methods(:always_fails))
      @site.capabilities(true).class.should == Subscription::ProblemWithPayment::Capabilities
    end

    it 'should return the right capabilities if a payment issue has been resolved' do
      @site.change_subscription(@pro, payment_methods(:always_fails))

      expect(@site.capabilities(true).remove_branding?).to be_false
      expect(@site.capabilities(true).closable?).to be_false
      expect(@site.site_elements.all? { |se| se.show_branding }).to be_true
      expect(@site.site_elements.all? { |se| se.closable }).to be_true

      @site.change_subscription(@pro, payment_methods(:always_successful))

      expect(@site.capabilities(true).remove_branding?).to be_true
      expect(@site.capabilities(true).closable?).to be_true
      expect(@site.site_elements.none? { |se| se.show_branding }).to be_true
      expect(@site.site_elements.none? { |se| se.closable }).to be_true
    end

    it "should return the right capabilities if payment is not due yet" do
      success, bill = @site.change_subscription(@pro, payment_methods(:always_fails))

      @site.capabilities(true).class.should == Subscription::ProblemWithPayment::Capabilities
      # Make the bill not due until later
      bill.bill_at += 10.days
      bill.save!
      @site.capabilities(true).class.should == Subscription::Pro::Capabilities
    end

    it "should return the right capabilities based on the active period of the Bill" do
      @site.change_subscription(@enterprise, @payment_method)
      @site.capabilities(true).class.should == Subscription::Enterprise::Capabilities
      @site.change_subscription(@pro, @payment_method)
      # Should still be on enterprise capabilities
      @site.capabilities(true).class.should == Subscription::Enterprise::Capabilities
    end

    it "should handle refund, switch, and void" do
      success, pro_bill = @site.change_subscription(@pro, @payment_method)
      success.should be_true
      @site.capabilities(true).class.should == Subscription::Pro::Capabilities

      # Refund
      refund_bill, refund_attempt = pro_bill.refund!
      refund_bill.should be_paid
      refund_attempt.should be_successful
      # Should still have pro cabalities
      @site.capabilities(true).class.should == Subscription::Pro::Capabilities
      # Should have a pending bill for pro
      pending = @site.bills(true).reject{|b| !b.pending?}
      pending.should have(1).bill
      pending.first.subscription.should be_a(Subscription::Pro)

      # Switch to Free
      success, free_bill = @site.change_subscription(@free, @payment_method)
      success.should be_true
      # Should still have pro capabilities
      @site.capabilities(true).class.should == Subscription::Pro::Capabilities
      # Should have a pending bill for free
      pending = @site.bills(true).reject{|b| !b.pending?}
      pending.should have(1).bill
      pending.first.subscription.should be_a(Subscription::Free)

      # Void the paid bill
      pro_bill.void!
      # Should not have pro capabilities
      @site.capabilities(true).class.should == Subscription::Free::Capabilities
      # Should still have a pending bill for free
      pending = @site.bills(true).reject{|b| !b.pending?}
      pending.should have(1).bill
      pending.first.subscription.should be_a(Subscription::Free)
    end

    it "should return the default visit_overage for the plan" do
      Subscription::Pro.create.capabilities.visit_overage.should == Subscription::Pro.defaults[:visit_overage]
    end

    it "should let you override the visit_overage for the plan" do
      Subscription::Pro.create(visit_overage: 3).capabilities.visit_overage.should == 3
    end

    it "gives the greatest capability of all current paid subscriptions" do
      # Auto pays each of these
      @site.change_subscription(@enterprise, @payment_method)
      @site.change_subscription(@pro, @payment_method)
      @site.change_subscription(@free, @payment_method)
      expect(@site.capabilities(true)).to be_a(Subscription::Enterprise::Capabilities)
    end

    it "stays at pro capabilities until bill period is over" do
      successful, bill = @site.change_subscription(@pro, @payment_method)
      bill.update_attribute(:end_date, 1.year.from_now)
      expect(@site.capabilities(true)).to be_a(Subscription::Pro::Capabilities)
      travel_to 2.year.from_now do
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
        @site.capabilities.at_site_element_limit?.should be_false
      end

      it 'returns false when it can still add site elements' do
        max_elements = @site.capabilities.max_site_elements
        elements = ['element'] * max_elements
        @site.stub site_elements: elements

        @site.capabilities.at_site_element_limit?.should be_true
      end
    end

    describe Subscription::ProblemWithPayment do
      it "should default to Free plan capabilities" do
        Subscription::ProblemWithPayment.create.capabilities.visit_overage.should == Subscription::Free.defaults[:visit_overage]
      end

      it "should not let you override the visit_overage for the plan" do
        Subscription::ProblemWithPayment.create(visit_overage: 3).capabilities.visit_overage.should == Subscription::Free.defaults[:visit_overage]
      end
    end
  end
end

describe Site do
  include SubscriptionHelper

  it "should return Free capabilities if no subscription" do
    Site.new.capabilities.class.should == Subscription::Free::Capabilities
  end

  it "should return the latest subscription capabilities otherwise" do
    s = Site.new
    s.subscriptions << Subscription::Pro.create
    s.capabilities(true).class.should == Subscription::Pro::Capabilities
    s.subscriptions << Subscription::Enterprise.create
    s.capabilities(true).class.should == Subscription::Enterprise::Capabilities
  end

  describe "change_subscription" do
    fixtures :all

    before do
      setup_subscriptions
    end

    it "should work with starting on a Free plan with no payment_method" do
      success, bill = @site.change_subscription(@free)
      success.should be_true
      bill.should be_paid
      bill.amount.should == 0
      @site.current_subscription.should == @free
      @site.capabilities.class.should == Subscription::Free::Capabilities
    end

    it "should work with starting out on a Free plan" do
      success, bill = @site.change_subscription(@free, @payment_method)
      success.should be_true
      bill.should be_paid
      bill.amount.should == 0
      @site.current_subscription.should == @free
      @site.capabilities.class.should == Subscription::Free::Capabilities
    end

    it "should charge a full amount for starting out a new plan for the first time" do
      success, bill = @site.change_subscription(@pro, @payment_method)
      success.should be_true
      bill.should be_paid
      bill.should be_persisted
      bill.amount.should == @pro.amount
      bill.bill_at.should <= Time.now
      @site.current_subscription.should == @pro
      @site.capabilities.class.should == Subscription::Pro::Capabilities
    end

    it "should let you preview a subscription without actually changing anything" do
      bill = @site.preview_change_subscription(@pro)
      bill.should_not be_paid
      bill.should_not be_persisted
      bill.amount.should == @pro.amount
      bill.bill_at.should <= Time.now
      lambda{bill.save!}.should raise_error(ActiveRecord::ReadOnlyRecord)
      bill.should_not be_persisted
      @site.current_subscription.should_not == @pro
      @site.capabilities.class.should == Subscription::Free::Capabilities
    end

    it "should charge full amount if you were on a Free plan" do
      success, bill = @site.change_subscription(@free, @payment_method)
      success.should be_true
      @site.current_subscription.should == @free
      success, bill = @site.change_subscription(@pro, @payment_method)
      success.should be_true
      bill.should be_paid
      bill.amount.should == @pro.amount
      @site.current_subscription.should == @pro
      @site.capabilities(true).class.should == Subscription::Pro::Capabilities
    end

    it "should work to downgrade to a free plan" do
      success, pro_bill = @site.change_subscription(@pro, @payment_method)
      success.should be_true
      pro_bill.should be_paid
      pro_bill.amount.should == @pro.amount
      @site.current_subscription.should == @pro
      @site.capabilities(true).class.should == Subscription::Pro::Capabilities
      success, bill = @site.change_subscription(@free, @payment_method)
      success.should be_true
      bill.should be_pending
      bill.amount.should == 0
      @site.current_subscription.should == @free
      # should still have pro
      @site.capabilities(true).class.should == Subscription::Pro::Capabilities
      # after it expires no longer have pro
      pro_bill.start_date -= 2.years
      pro_bill.end_date -= 2.years
      pro_bill.save!
      @site.capabilities(true).class.should == Subscription::Free::Capabilities

    end

    it "should prorate if you are upgrading and were on a paid plan" do
      success, bill = @site.change_subscription(@pro, @payment_method)
      success.should be_true
      @site.current_subscription.should == @pro
      success, bill = @site.change_subscription(@enterprise, @payment_method)
      success.should be_true
      bill.should be_paid
      bill.amount.should == @enterprise.amount-@pro.amount
      @site.current_subscription.should == @enterprise
      @site.capabilities(true).should be_a(Subscription::Enterprise::Capabilities)
    end

    it "should not have prorating affected by refund" do
      success, bill1 = @site.change_subscription(@pro, @payment_method)
      success.should be_true
      @site.current_subscription.should == @pro
      bill1.refund!
      success, bill2 = @site.change_subscription(@enterprise, @payment_method)
      success.should be_true
      bill2.should be_paid
      bill2.amount.should == @enterprise.amount-@pro.amount
      @site.current_subscription.should == @enterprise
      @site.capabilities(true).should be_a(Subscription::Enterprise::Capabilities)
    end

    it "should affect prorating if you refund and switch plan" do
      success, pro_bill = @site.change_subscription(@pro, @payment_method)
      success.should be_true

      # Refund
      refund_bill, refund_attempt = pro_bill.refund!
      refund_bill.should be_paid
      refund_attempt.should be_successful

      # Switch to Free
      success, free_bill = @site.change_subscription(@free, @payment_method)
      success.should be_true

      # Switch to enterprise
      success, enterprise_bill = @site.change_subscription(@enterprise, @payment_method)
      success.should be_true
      # Should still prorate
      enterprise_bill.amount.should == @enterprise.amount-@pro.amount
    end

    it "should affect prorating if you refund and switch plan" do
      success, pro_bill = @site.change_subscription(@pro, @payment_method)
      success.should be_true

      # Refund
      refund_bill, refund_attempt = pro_bill.refund!
      refund_bill.should be_paid
      refund_attempt.should be_successful

      # Switch to Free
      success, free_bill = @site.change_subscription(@free, @payment_method)
      success.should be_true
      # Void the pro bill
      pro_bill.void!

      # Switch to enterprise
      success, enterprise_bill = @site.change_subscription(@enterprise, @payment_method)
      success.should be_true
      # NO prorating
      enterprise_bill.amount.should == @enterprise.amount
    end

    it "should prorate based on amount of time used from a paid plan" do
      success, bill = @site.change_subscription(@pro, @payment_method)
      success.should be_true
      # Have used up 1/4 of bill
      one_fourth_time = (bill.end_date-bill.start_date)/4
      bill.start_date -= one_fourth_time
      bill.end_date -= one_fourth_time
      bill.save!
      @site.current_subscription.should == @pro
      success, bill = @site.change_subscription(@enterprise, @payment_method)
      success.should be_true
      bill.should be_paid
      # Only going to apply 75% of pro payment since we used up 25% (1/4) of it
      bill.amount.should == (@enterprise.amount-@pro.amount*(0.75)).to_i
      @site.current_subscription.should == @enterprise
      @site.capabilities(true).class.should == Subscription::Enterprise::Capabilities
    end

    it "should start your new plan after your current plan if you are downgrading" do
      success, enterprise_bill = @site.change_subscription(@enterprise, @payment_method)
      success.should be_true
      @site.current_subscription.should == @enterprise
      success, bill = @site.change_subscription(@pro, @payment_method)
      success.should be_true
      bill.should be_pending
      bill.amount.should == @pro.amount
      bill.start_date.should be_within(2.hour).of(enterprise_bill.end_date)
      bill.grace_period_allowed.should be_true
      # Should still have enterprise abilities
      @site.current_subscription.should == @pro
      @site.capabilities.class.should == Subscription::Enterprise::Capabilities
    end

    it "should charge full amount if you used to be on a paid plan but are no longer on one" do
      success, bill = @site.change_subscription(@pro, @payment_method)
      success.should be_true
      @site.current_subscription.should == @pro
      bill.start_date = Time.now-2.years
      bill.end_date = Time.now-1.year
      bill.save!
      success, bill = @site.change_subscription(@enterprise, @payment_method)
      success.should be_true
      bill.should be_paid
      bill.amount.should == @enterprise.amount
      @site.current_subscription.should == @enterprise
      @site.capabilities(true).class.should == Subscription::Enterprise::Capabilities
    end

    it "should charge full amount and void pending recurring payment if pending payment" do
      pending_bill = Bill::Recurring.create(subscription: @pro, status: :pending, amount: 25)
      pending_bill.should be_pending
      success, bill = @site.change_subscription(@enterprise, @payment_method)
      success.should be_true
      bill.should be_paid
      bill.amount.should == @enterprise.amount
      @site.current_subscription.should == @enterprise
      @site.capabilities(true).class.should == Subscription::Enterprise::Capabilities
      pending_bill = Bill.find(pending_bill.id)
      pending_bill.should be_voided
    end

    it "should charge full amount and ignore pending overage payment if pending payment" do
      pending_bill = Bill::Overage.create(subscription: @pro, status: :pending, amount: 25)
      pending_bill.should be_pending
      success, bill = @site.change_subscription(@enterprise, @payment_method)
      success.should be_true
      bill.should be_paid
      bill.amount.should == @enterprise.amount
      @site.current_subscription.should == @enterprise
      @site.capabilities(true).class.should == Subscription::Enterprise::Capabilities
      pending_bill = Bill.find(pending_bill.id)
      pending_bill.should be_pending
    end


    it "should return false if payment fails" do
      success, bill = @site.change_subscription(@pro, payment_methods(:always_fails))
      success.should be_false
      bill.should be_pending
      bill.amount.should == @pro.amount
      @site.current_subscription.should == @pro
      @site.capabilities(true).class.should == Subscription::ProblemWithPayment::Capabilities
    end

    it "should not create a negative bill when switching from yearly to monthly" do
      pro_yearly = Subscription::Pro.new(user: @user, site: @site, schedule: "yearly")
      pro_monthly = Subscription::Pro.new(user: @user, site: @site, schedule: "monthly")

      success, bill = @site.change_subscription(pro_yearly, @payment_method)
      success.should be_true
      bill.amount.should == pro_yearly.amount
      bill.should be_paid

      success, bill2 = @site.change_subscription(pro_monthly, @payment_method)
      success.should be_true
      bill2.amount.should > 0
      # Bill should be full amount
      bill2.amount.should == pro_monthly.amount
      # Bill should be due at end of yearly subscription
      bill2.due_at.should be_within(2.hour).of(bill.due_at+1.year)
      # Bill should be pending
      bill2.should be_pending
    end
  end

  describe "bills_with_payment_issues" do
    fixtures :all
    before do
      setup_subscriptions
    end

    it "should return bills that are due" do
      @site.bills_with_payment_issues(true).should == []
      success, bill = @site.change_subscription(@pro, payment_methods(:always_fails))
      success.should be_false
      bill.should be_pending
      @site.bills_with_payment_issues(true).should == [bill]
    end

    it "should not return bills not due" do
      @site.bills_with_payment_issues(true).should == []
      success, bill = @site.change_subscription(@pro, payment_methods(:always_fails))
      success.should be_false
      bill.should be_pending
      # Make it due later
      bill.bill_at = Time.now+7.days
      bill.save!
      @site.bills_with_payment_issues(true).should == []
    end

    it "should not return bills that we haven't attempted to charge at least once" do
      @site.bills_with_payment_issues(true).should == []
      success, bill = @site.change_subscription(@pro, payment_methods(:always_fails))
      success.should be_false
      bill.should be_pending
      # Delete the attempt
      # We have to do this monkey business to get around the fact that
      # BillingAttmps are read only
      BillingAttempt.connection.execute("TRUNCATE #{BillingAttempt.table_name}")
      @site.bills_with_payment_issues(true).should == []
    end
  end
end
