class AlwaysSuccessfulPaymentMethodDetails < PaymentMethodDetails
  def charge(_amount_in_dollars)
    [true, "fake-txn-id-#{ Time.current.to_i }"]
  end

  def refund(_amount_in_dollars, original_transaction_id)
    [true, "fake-refund-id-#{ Time.current.to_i } (original: #{ original_transaction_id }"]
  end

  def data
    {}
  end
end

class AlwaysFailsPaymentMethodDetails < PaymentMethodDetails
  def charge(_amount_in_dollars)
    [false, 'There was some issue with your payment (fake)']
  end

  def refund(_amount_in_dollars, _original_transaction_id)
    [false, 'There was some issue with your refund (fake)']
  end
end

class FakeCyberSourceCreditCard < CyberSourceCreditCard
  def save_to_cybersource
  end
end
