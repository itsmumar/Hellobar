require 'spec_helper'

describe BillingAttempt do
  it "should be read-only" do
    b = BillingAttempt.create
    b.response = "different"
    lambda{b.save}.should raise_error(ActiveRecord::ReadOnlyRecord)
    lambda{b.destroy}.should raise_error(ActiveRecord::ReadOnlyRecord)
  end
end
