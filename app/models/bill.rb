require 'billing_log'

class Bill < ActiveRecord::Base
  class StatusChanged < Exception; end
  serialize :metadata, JSON
  belongs_to :subscription
  include BillingAuditTrail
  delegate :site, to: :subscription
  delegate :site_id, to: :subscription

  enum status: [:pending, :paid, :voided]

  def status=(value)
    return if self.status == value
    raise StatusChanged.new("Can not change status once set. Was #{self.status.inspect} trying to set to #{value.inspect}") unless self.status == :pending

    audit << "Changed status from #{self.status.inspect} to #{value.inspect}"
    write_attribute(:status, value)
    self.changed_status_at = Time.now

    if status == :paid
      on_paid
    elsif status == :voided
      on_voided
    end
  end

  def due_at(payment_method=nil)
    if self.grace_period_allowed and payment_method and payment_method.current_details and payment_method.current_details.grace_period
      return self.bill_at+payment_method.current_details.grace_period
    end
    # Otherwise it is due now
    return self.bill_at
  end

  def on_paid
  end

  def on_voided
  end

  class Recurring < Bill
    def on_paid
      super
      # Create the next bill
    end
  end

  class Overage < Bill
  end
end
