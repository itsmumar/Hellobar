require 'billing_log'

class Bill < ActiveRecord::Base
  class StatusAlreadySet < Exception; end
  class InvalidStatus < Exception; end
  serialize :metadata, JSON
  belongs_to :subscription
  validates_presence_of :subscription
  include BillingAuditTrail
  delegate :site, to: :subscription
  delegate :site_id, to: :subscription

  enum status: [:pending, :paid, :voided]

  def status=(value)
    value = value.to_sym
    return if self.status == value
    raise StatusAlreadySet.new("Can not change status once set. Was #{self.status.inspect} trying to set to #{value.inspect}") unless self.status == :pending

    audit << "Changed status from #{self.status.inspect} to #{value.inspect}"
    status_value = Bill.statuses[value.to_sym]
    raise InvalidStatus.new("Invalid status: #{value.inspect}") unless status_value
    write_attribute(:status, status_value)
    self.status_set_at = Time.now

    if status == :paid
      on_paid
    elsif status == :voided
      on_voided
    end
  end

  alias :orig_status :status
  def status
    orig_status.to_sym
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
