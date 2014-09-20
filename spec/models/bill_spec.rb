require 'spec_helper'

describe Bill do
  it "should not let you change the status once set" do
    pending
  end

  it "should record when the status was changed" do
    pending
  end

  it "should take the payment_method grace period into account when grace_period_allowed" do
    pending
  end

  describe Bill::Recurring do
    it "should create the next bill once paid" do
      pending
    end
  end
end

describe Subscription do
  it "should return all pending bills" do
    pending
  end

  it "should return all paid bills" do
    pending
  end

  it "should return all bills active for time period" do
    pending
  end
end
