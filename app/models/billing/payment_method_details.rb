require 'billing_log'

class PaymentMethodDetails < ActiveRecord::Base
  include BillingAuditTrail

  belongs_to :payment_method
  has_many :billing_attempts

  # For auditing purposes
  has_one :user, through: :payment_method
  delegate :id, to: :user, prefix: true

  serialize :data, JSON

  def readonly?
    new_record? ? false : true
  end

  def grace_period
    nil
  end

  def name
    raise NameError, 'must be implemented'
  end

  def charge(_amount_in_dollars)
    raise NameError, 'must be implemented'
  end

  def refund(_amount_in_dollars, _original_transaction_id)
    raise NameError, 'must be implemented'
  end
end
