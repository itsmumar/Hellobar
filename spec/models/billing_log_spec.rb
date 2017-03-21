require 'spec_helper'

describe BillingLog do
  it 'should not let you edit a BillingLog' do
    log = BillingLog.create(message: 'test')
    log.message = 'test2'
    expect { log.save! }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end
end

describe BillingAuditTrail do
  before do
    BillingLog.connection.execute("DELETE FROM #{ BillingLog.table_name }")
  end

  let(:user) { create(:user) }

  it 'should allow us to call audit on an object' do
    expect(BillingLog.count).to eq(0)
    message = 'Hello Audit'
    user.audit << message
    expect(BillingLog.count).to eq(1)
    log = BillingLog.all.first
    expect(log.message).to eq(message)
    expect(log.created_at).to be_within(2).of(Time.current)
  end

  it 'should allow us to call audit on an object and set the source ID correctly' do
    expect(BillingLog.count).to eq(0)
    user.audit << 'Hello Audit'
    expect(BillingLog.count).to eq(1)
    log = BillingLog.all.first
    expect(log.user_id).to eq(user.id)
    expect(log.user_id).not_to be_nil
  end

  it 'should set the source ID correctly' do
    expect(BillingLog.count).to eq(0)
    user.audit << 'Hello Audit'
    expect(BillingLog.count).to eq(1)
    log = BillingLog.all.first
    expect(log.user_id).to eq(user.id)
    expect(log.user_id).not_to be_nil
  end

  it 'should set additional lookup ids' do
    payment_method = PaymentMethod.create!(user: user)
    payment_method_details = PaymentMethodDetails.create!(payment_method: payment_method)

    payment_method_details.audit << 'Hello'
    expect(BillingLog.count).to eq(1)
    log = BillingLog.all.first
    expect(log.payment_method_details_id).to eq(payment_method_details.id)
    expect(log.payment_method_id).to eq(payment_method.id)
    expect(log.user_id).to eq(user.id)
    expect(log.user_id).not_to be_nil
  end

  it 'should include the line number, file and current git revision' do
    expect(BillingLog.count).to eq(0)
    User.new.audit << 'Test'
    expect(BillingLog.count).to eq(1)
    log = BillingLog.all.first

    # we have to escape everything in this string because sometimes - if you're in a detached head state, for instance - the
    # value of GitUtils.current_commit will be "???" or something else that will potentially mess up the regex
    current_commit = GitUtils.current_commit.gsub(/.{1}/) { |m| m =~ /[a-z0-9]/ ? m : "\\#{ m }" }

    expect(log.source_file).to match(/#{current_commit} @ .*?billing_log_spec\.rb:#{__LINE__ - 8}/)
  end
end
