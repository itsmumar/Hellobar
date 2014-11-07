require 'spec_helper'

describe UrlCondition do
  fixtures :all

  it "clears empty values during validation" do
    condition = UrlCondition.new(
      rule: rules(:zombo),
      operand: "is",
      value: ["/foo", "/bar", ""]
    )

    condition.should be_valid
    condition.value.should == ["/foo", "/bar"]
  end
end
