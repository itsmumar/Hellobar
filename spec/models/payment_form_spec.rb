describe PaymentForm do
  let(:params) { create :payment_form_params }
  let(:payment_form) { PaymentForm.new params }

  describe '#attributes' do
    let(:params) { create :payment_form_params, number: '4242 4242 4242 4242' }

    it 'returns sanitized attributes' do
      expect(payment_form.attributes[:number]).to eql 'XXXX-XXXX-XXXX-4242'
    end
  end

  describe 'validation' do
    subject { payment_form }
    specify { expect(payment_form).to be_valid }

    specify { is_expected.to validate_presence_of :number }
    specify { is_expected.to validate_presence_of :expiration }
    specify { is_expected.to validate_presence_of :name }
    specify { is_expected.to validate_presence_of :city }
    specify { is_expected.to validate_presence_of :zip }
    specify { is_expected.to validate_presence_of :address }
    specify { is_expected.to validate_presence_of :country }
    specify { is_expected.to validate_presence_of :verification_value }
    specify { is_expected.to validate_presence_of :state }

    context 'with 2 numbers year' do
      let(:payment_form) { PaymentForm.new(params.update(expiration: '08/99')) }

      specify { expect(payment_form).to be_valid }
    end

    context 'when outside US and state is blank' do
      subject { PaymentForm.new(params.update(country: 'UK', state: nil)) }

      specify { is_expected.not_to validate_presence_of :state }
    end

    context 'when number contains spaces' do
      let(:payment_form) { PaymentForm.new(params.update(number: '4242 4242 4242 4242')) }
      specify { expect(payment_form).to be_valid }

      context '.number' do
        specify { expect(payment_form.number).not_to include ' ' }
      end
    end

    context 'when could not split the name to first and last' do
      let(:payment_form) { PaymentForm.new(params.update(name: 'First')) }
      before { payment_form.valid? }
      specify { expect(payment_form).to be_invalid }
      specify { expect(payment_form.errors[:name]).to eql ['must contain first and last names'] }
    end

    context 'when expired' do
      let(:payment_form) { PaymentForm.new(params.update(expiration: '1/2000')) }
      specify { expect(payment_form).to be_invalid }
    end
  end

  describe '.card' do
    it 'returns ActiveMerchant::Billing::CreditCard' do
      expect(payment_form.card).to be_a ActiveMerchant::Billing::CreditCard
      expect(payment_form.card.validate).to be_empty
    end
  end

  describe '.address_attributes' do
    it 'returns OpenStruct' do
      expect(payment_form.address_attributes).to match(
        country: payment_form.country,
        city: payment_form.city,
        state: payment_form.state,
        address1: payment_form.address,
        zip: payment_form.zip
      )
    end
  end
end
