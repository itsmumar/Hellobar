require 'spec_helper'
describe Font do
  before(:each) do
    @valid_attributes = { }
  end
  it "should create a new instance given valid attributes" do
    Font.create!(@valid_attributes)
  end
end
