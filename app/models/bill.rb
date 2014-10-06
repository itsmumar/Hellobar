require 'billing_log'

class Bill < ActiveRecord::Base
  class StatusAlreadySet < Exception; end
  class InvalidStatus < Exception; end
  class BillingEarly < Exception; end
  serialize :metadata, JSON
  belongs_to :subscription
  has_many :billing_attempts
  validates_presence_of :subscription
  include BillingAuditTrail
  delegate :site, to: :subscription
  delegate :site_id, to: :subscription

  enum status: [:pending, :paid, :voided]

  alias :void! :voided!
  def status=(value)
    value = value.to_sym
    return if self.status == value
    raise StatusAlreadySet.new("Can not change status once set. Was #{self.status.inspect} trying to set to #{value.inspect}") unless self.status == :pending

    audit << "Changed Bill[#{self.id}] status from #{self.status.inspect} to #{value.inspect}"
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

  def attempt_billing!(allow_early=false)
    now = Time.now
    raise BillingEarly.new("Attempted to bill on #{now} but bill[#{self.id}] has a bill_at date of #{self.bill_at}") if !allow_early and now < self.bill_at  
    if self.subscription.requires_payment_method?
      return self.subscription.payment_method.pay(self)
    else
      audit << "Marking bill as paid because no payment method required"
      # Mark as paid
      self.paid!
      return true
    end
  end

  alias :orig_status :status
  def status
    orig_status.to_sym
  end

  def active_during(date)
    return false if voided?
    return false if start_date and start_date > date
    return false if end_date and end_date < date
    return true
  end

  def due_at(payment_method=nil)
    if self.grace_period_allowed and payment_method and payment_method.current_details and payment_method.current_details.grace_period
      return self.bill_at+payment_method.current_details.grace_period
    end
    # Otherwise it is due now
    return self.bill_at
  end

  def past_due?(payment_method=nil)
    return Time.now > due_at(payment_method)
  end

  def should_bill?
    return (self.pending? and Time.now >= self.bill_at)
  end

  def problem_with_payment?(payment_method=nil)
    return false if paid? || voided? || self.amount == 0
    # If pending see if we are past due and we have
    # tried billing them at least once
    return true if past_due?(payment_method) and self.billing_attempts.size > 0
    # False otherwise
    return false

  end

  def on_paid
  end

  def on_voided
  end

  def paid_with_payment_method_detail
    billing_attempts.find{|attempt| attempt.success? }.
                     try(:payment_method_details)
  end

  class Recurring < Bill
    class << self
      def next_month(date)
        date+1.month
      end

      def next_year(date)
        date+1.year
      end
    end

    def renewal_date
      raise "can not calculate renewal date without start_date" unless start_date
      self.subscription.monthly? ? self.class.next_month(start_date) : self.class.next_year(start_date)
    end

    def on_paid
      super
      # Create the next bill
      next_method = self.subscription.monthly? ? :next_month : :next_year
      new_start_date = self.end_date
      new_bill = Bill::Recurring.new(
        subscription: self.subscription,
        amount: self.subscription.amount,
        description: "#{self.subscription.monthly? ? "Monthly" : "Yearly"} Renewal",
        grace_period_allowed: true,
        bill_at: Bill::Recurring.send(next_method, self.bill_at),
        start_date: new_start_date,
        end_date: Bill::Recurring.send(next_method, new_start_date)
      )
      audit << "Paid recurring bill, created new bill for #{subscription.amount} that starts at #{new_start_date}. #{new_bill.inspect}"
      new_bill.save!
      new_bill
    end
  end

  class Overage < Bill
  end
end
