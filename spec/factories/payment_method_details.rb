class AlwaysSuccessfulPaymentMethodDetails < PaymentMethodDetails
  def charge(_amount_in_dollars)
    [true, "fake-txn-id-#{ Time.now.to_i }"]
  end

  def refund(_amount_in_dollars, original_transaction_id)
    [true, "fake-refund-id-#{ Time.now.to_i } (original: #{ original_transaction_id }"]
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

FactoryGirl.define do
  factory :payment_method_details do
    factory :always_successful_billing_details, class: 'AlwaysSuccessfulPaymentMethodDetails' do
    end

    factory :always_fails_payment_method_details, class: 'AlwaysFailsPaymentMethodDetails' do
    end

    factory :cyber_source_credit_card, class: 'FakeCyberSourceCreditCard' do
      payment_method

      data do
        {
          'number' => '4012 8888 8888 1881',
          'month' => 12,
          'year' => Date.current.year + 1,
          'first_name' => 'John',
          'last_name' => 'Doe',
          'address1' => 'Sunset Blv 205',
          'city' => 'San Francisco',
          'state' => 'CA',
          'zip' => '94016',
          'country' => 'US',
          'brand' => 'visa',
          'verification_value' => '777',
          'token' => 'cc_token'
        }
      end
    end
  end
end
