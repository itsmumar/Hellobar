require 'billing_log'
require 'payment_method'

class PaymentMethodDetails < ActiveRecord::Base
  belongs_to :payment_method
  has_many :billing_attempts
  serialize :data, JSON
  include BillingAuditTrail
  # For auditing purposes
  delegate :user, to: :payment_method
  delegate :user_id, to: :payment_method

  def readonly?
    new_record? ? false : true
  end

  def grace_period
    nil
  end

  def name
    raise NotImplementedError
  end

  def charge(amount_in_dollars)
    raise NotImplementedError
  end

  def refund(amount_in_dollars, original_transaction_id)
    raise NotImplementedError
  end
end

if Rails.env.test?
  class AlwaysSuccessfulPaymentMethodDetails < PaymentMethodDetails
    def charge(amount_in_dollars)
      return true, "fake-txn-id-#{Time.now.to_i}"
    end

    def refund(amount_in_dollars, original_transaction_id)
      return true, "fake-refund-id-#{Time.now.to_i} (original: #{original_transaction_id}"
    end

    def data
      {}
    end
  end

  class AlwaysFailsPaymentMethodDetails < PaymentMethodDetails
    def charge(amount_in_dollars)
      return false, 'There was some issue with your payment (fake)'
    end

    def refund(amount_in_dollars, original_transaction_id)
      return false, 'There was some issue with your refund (fake)'
    end
  end
end

require 'cybersource'
