describe ChargebackBill do
  subject(:service) { described_class.new(bill) }

  # let(:subscription) { create(:subscription, :pro) }
  let!(:bill) { create(:bill, :pro, :paid) }

  before do
    allow(ChangeSubscription).to receive_service_call
  end

  describe '#call' do
    it 'switches status of given bill to chargedback', :freeze do
      service.call
      expect(bill).to be_chargedback
    end

    it 'creates a new BillingAttempt record' do
      expect { service.call }.to change(BillingAttempt.chargeback.successful, :count).by(1)
    end

    it 'downgrades subscription to free' do
      expect(ChangeSubscription).to receive_service_call.with(bill.site, subscription: 'free')

      service.call
    end
  end

  context 'when BillingAttempt record creation failed' do
    let(:error) { ActiveRecord::RecordInvalid.new(BillingAttempt.new) }

    before do
      allow(bill).to receive_message_chain(:billing_attempts, :create!).and_raise(error)
    end

    it 'does not downgrade the subscription' do
      expect(ChangeSubscription).not_to receive_service_call

      service.call rescue nil # rubocop:disable Style/RescueModifier
    end

    it 'raises error' do
      expect { service.call }.to raise_error(error)
    end
  end

  context 'when subscription downgrade is failed' do
    let(:error) { ActiveRecord::RecordInvalid.new(bill.subscription) }

    before do
      allow(ChangeSubscription).to receive_message_chain(:new, :call).and_raise(error)
    end

    it 'does not create a new BillingAttempt record' do
      expect { service.call rescue nil }.not_to change { BillingAttempt.count } # rubocop:disable Style/RescueModifier
    end

    it 'raises error' do
      expect { service.call }.to raise_error(error)
    end
  end
end
