describe BillingAttempt do
  it { is_expected.to validate_presence_of(:status) }
  it { is_expected.to validate_inclusion_of(:status).in_array(BillingAttempt::STATUSES) }
  it { is_expected.to validate_presence_of(:action) }
  it { is_expected.to validate_inclusion_of(:action).in_array(BillingAttempt::ACTIONS) }

  it 'should be read-only' do
    b = BillingAttempt.create
    b.response = 'different'
    expect { b.save }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { b.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  specify('is pending by default') { expect(BillingAttempt.new).to be_pending }
  specify('could be successful') { expect(build(:billing_attempt)).to be_successful }
  specify('could be failed') { expect(build(:billing_attempt, :failed)).to be_failed }
end
