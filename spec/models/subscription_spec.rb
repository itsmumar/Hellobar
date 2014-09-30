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
  include SubscriptionHelper
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

  describe Subscription::Capabilities do
    fixtures :all
    before do
      setup_subscriptions
    end

    it "should return default capabilities for plan" do
      @site.capabilities(true).class.should == Subscription::Free::Capabilities
      @site.change_subscription(@pro, @payment_method)
      @site.capabilities(true).class.should == Subscription::Pro::Capabilities
    end
    
    it "should return ProblemWithPayment capabilities if on a paid plan and payment has not been made" do
      @site.change_subscription(@pro, payment_methods(:always_fails))
      @site.capabilities(true).class.should == Subscription::ProblemWithPayment::Capabilities
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

    it "should return the default visit_overage for the plan" do
      Subscription::Pro.create.capabilities.visit_overage.should == Subscription::Pro.defaults[:visit_overage]
    end

    it "should let you override the visit_overage for the plan" do
      Subscription::Pro.create(visit_overage: 3).capabilities.visit_overage.should == 3
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
      bill.start_date.to_i.should == enterprise_bill.end_date.to_i
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
