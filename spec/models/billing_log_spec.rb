require 'spec_helper'

describe BillingLog do
  it "should not let you edit a BillingLog" do
    log = BillingLog.create(:message=>"test")
    log.message = "test2"
    lambda{log.save!}.should raise_error(ActiveRecord::ReadOnlyRecord)
  end
end

describe BillingAuditTrail do
  fixtures :all
  before do
    BillingLog.connection.execute("DELETE FROM #{BillingLog.table_name}")
  end

  it "should allow us to call audit on an object" do
    BillingLog.count.should == 0
    user = users(:joey)
    message = "Hello Audit"
    user.audit << message
    BillingLog.count.should == 1
    log = BillingLog.all.first
    log.message.should == message
    log.created_at.should be_within(1).of(Time.now)
  end

  it "should allow us to call audit on an object and set the source ID correctly" do
    BillingLog.count.should == 0
    user = users(:joey)
    user.audit << "Hello Audit"
    BillingLog.count.should == 1
    log = BillingLog.all.first
    log.user_id.should == user.id
    log.user_id.should_not be_nil
  end

  it "should set the source ID correctly" do
    BillingLog.count.should == 0
    user = users(:joey)
    user.audit << "Hello Audit"
    BillingLog.count.should == 1
    log = BillingLog.all.first
    log.user_id.should == user.id
    log.user_id.should_not be_nil
  end

  it "should set additional lookup ids" do
    user = users(:joey)
    payment_method = PaymentMethod.create!(:user=>user)
    payment_method_details = PaymentMethodDetails.create!(:payment_method=>payment_method)

    payment_method_details.audit << "Hello"
    BillingLog.count.should == 1
    log = BillingLog.all.first
    log.payment_method_details_id.should == payment_method_details.id
    log.payment_method_id.should == payment_method.id
    log.user_id.should == user.id
    log.user_id.should_not be_nil
  end

  it "should include the line number, file and current git revision" do
    BillingLog.count.should == 0
    User.new.audit << "Test"
    BillingLog.count.should == 1
    log = BillingLog.all.first
    log.source_file.should =~ /#{GitUtils.current_commit} @ .*?billing_log_spec\.rb:#{__LINE__-3}/
  end

  
end
