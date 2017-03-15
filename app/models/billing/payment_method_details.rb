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

  def charge(_amount_in_dollars)
    raise NotImplementedError
  end

  def refund(_amount_in_dollars, _original_transaction_id)
    raise NotImplementedError
  end
end

require 'cybersource'
