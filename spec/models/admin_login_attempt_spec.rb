require 'spec_helper'
describe AdminLoginAttempt do
  before(:each) do
    @valid_attributes = {}
  end
  it 'should create a new instance given valid attributes' do
    AdminLoginAttempt.create!(@valid_attributes)
  end
end
