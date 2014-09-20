require 'spec_helper'

describe Subscription do
  it "should set defaults if not set" do
    Subscription::Pro.create.visit_overage.should == Subscription::Pro.defaults[:visit_overage]
  end

  it "should not override values set with defaults" do
    Subscription::Pro.create(:visit_overage=>3).visit_overage.should == 3
  end

  it "should default to monthly schedule" do
    Subscription::Pro.create.monthly?.should be_true
    Subscription::Pro.create.amount.should == Subscription::Pro.defaults[:monthly_amount]
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
    it "should return default capabilities for plan" do
      Subscription::Pro.create.capabilities.remove_branding?.should == true
    end
    
    it "should return ProblemWithPayment capabilities if on a paid plan and payment has not been made" do
      pending "Bills"
    end

    it "should return the right capabilities if payment is not due yet" do
      pending "Bills"
    end

    it "should return the right capabilities based on the active period of the Bill" do
      pending "Bills"
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
  it "should return Free capabilities if no subscription" do
    Site.new.capabilities.should be_a(Subscription::Free::Capabilities)
  end

  it "should return the latest subscription capabilities otherwise" do
    s = Site.new
    s.subscriptions << Subscription::Pro.create
    s.capabilities.should be_a(Subscription::Pro::Capabilities)
    s.subscriptions << Subscription::Enterprise.create
    s.capabilities.should be_a(Subscription::Enterprise::Capabilities)
  end
end
