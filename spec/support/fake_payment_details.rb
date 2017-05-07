class FakePaymentMethod < PaymentMethodDetails
  def data
    super || {}
  end

  def address
    OpenStruct.new(address1: 'address1', city: 'city', state: 'state', zip: 'zip', country: 'country')
  end

  def card
    @card ||=
      begin
        attributes =
          CyberSourceCreditCard::CC_FIELDS.inject({}) do |attrs, field|
            attrs.update field.to_sym => data[field] || data[field.to_sym]
          end
        ActiveMerchant::Billing::CreditCard.new(attributes)
      end
  end

  def token
    data['token']
  end
end

class AlwaysSuccessfulPaymentMethodDetails < FakePaymentMethod
  def charge(_amount_in_dollars)
    [true, "fake-txn-id-#{ Time.current.to_i }"]
  end

  def refund(_amount_in_dollars, original_transaction_id)
    [true, "fake-refund-id-#{ Time.current.to_i } (original: #{ original_transaction_id }"]
  end

  def brand
    'AlwaysSuccessfulPayment'
  end
end

class AlwaysFailsPaymentMethodDetails < FakePaymentMethod
  def charge(_amount_in_dollars)
    [false, 'There was some issue with your payment (fake)']
  end

  def refund(_amount_in_dollars, _original_transaction_id)
    [false, 'There was some issue with your refund (fake)']
  end

  def brand
    'AlwaysFailsPayment'
  end
end

class FakeCyberSourceCreditCard < CyberSourceCreditCard
  def save_to_cybersource
  end
end
