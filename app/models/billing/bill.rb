require 'billing_log'

class Bill < ActiveRecord::Base
  class StatusAlreadySet < StandardError; end
  class InvalidStatus < StandardError; end
  class BillingEarly < StandardError; end
  class InvalidBillingAmount < StandardError; end
  class MissingPaymentMethod < StandardError; end
  serialize :metadata, JSON
  belongs_to :subscription, inverse_of: :bills
  has_many :billing_attempts, -> { order 'id' }
  has_many :coupon_uses
  validates_presence_of :subscription
  include BillingAuditTrail
  delegate :site, to: :subscription
  delegate :site_id, to: :subscription

  enum status: [:pending, :paid, :voided]

  before_save :check_amount
  before_validation :set_base_amount, :check_amount

  def during_trial_subscription?
    subscription.amount != 0 && subscription.payment_method.nil? && \
    amount == 0 && paid?
  end

  def set_base_amount
    self.base_amount ||= amount
  end

  def check_amount
    raise InvalidBillingAmount, "Amount was: #{amount.inspect}" if !amount or amount < 0
  end

  alias :void! :voided!
  def status=(value)
    value = value.to_sym
    return if status == value
    raise StatusAlreadySet, "Can not change status once set. Was #{status.inspect} trying to set to #{value.inspect}" unless status == :pending || value == :voided

    audit << "Changed Bill[#{id}] status from #{status.inspect} to #{value.inspect}"
    status_value = Bill.statuses[value.to_sym]
    raise InvalidStatus, "Invalid status: #{value.inspect}" unless status_value
    write_attribute(:status, status_value)
    self.status_set_at = Time.now

    if status == :paid
      on_paid
    elsif status == :voided
      on_voided
    end
  end

  def attempt_billing!(allow_early = false)
    set_final_amount!

    now = Time.now
    raise BillingEarly, "Attempted to bill on #{now} but bill[#{id}] has a bill_at date of #{bill_at}" if !allow_early and now < bill_at
    if amount == 0 # Note: less than 0 is a valid value for refunds
      audit << 'Marking bill as paid because no payment required'
      # Mark as paid
      paid!
      return true
    else
      raise MissingPaymentMethod unless subscription.payment_method
      return subscription.payment_method.pay(self)
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
    true
  end

  def due_at(payment_method = nil)
    if grace_period_allowed and payment_method and payment_method.current_details and payment_method.current_details.grace_period
      return bill_at + payment_method.current_details.grace_period
    end
    # Otherwise it is due now
    bill_at
  end

  def past_due?(payment_method = nil)
    Time.now > due_at(payment_method)
  end

  def should_bill?
    (pending? and Time.now >= bill_at)
  end

  def problem_with_payment?(payment_method = nil)
    return false if paid? || voided? || amount == 0
    # If pending see if we are past due and we have
    # tried billing them at least once
    return true if past_due?(payment_method) and (payment_method.nil? || !billing_attempts.empty?)
    # False otherwise
    false
  end

  def on_paid
  end

  def on_voided
  end

  def paid_with_payment_method_detail
    successful_billing_attempt.try(:payment_method_details)
  end

  def successful_billing_attempt
    billing_attempts.find(&:success?)
  end

  # Can optionally specify a partial amount or description
  def refund!(description = nil, amount = nil)
    successful_billing_attempt.refund!(description, amount)
  end

  def calculate_discount
    calculator = DiscountCalculator.new(subscription)
    calculated_discount = calculator.current_discount
  end

  def set_final_amount!
    return if paid? || base_amount.nil?

    self.discount = is_a?(Refund) ? 0 : calculate_discount
    self.amount = [self.base_amount - discount, 0].max
    CouponUses::ApplyFromReferrals.run(bill: self)
  end

  def estimated_amount
    (base_amount || amount) - calculate_discount
  end

  class Recurring < Bill
    class << self
      def next_month(date)
        date + 1.month
      end

      def next_year(date)
        date + 1.year
      end
    end

    def renewal_date
      raise 'can not calculate renewal date without start_date' unless start_date
      subscription.monthly? ? self.class.next_month(start_date) : self.class.next_year(start_date)
    end

    def on_paid
      super
      # Create the next bill
      next_method = subscription.monthly? ? :next_month : :next_year
      new_start_date = end_date
      new_bill = Bill::Recurring.new(
        subscription: subscription,
        amount: subscription.amount,
        description: "#{subscription.monthly? ? 'Monthly' : 'Yearly'} Renewal",
        grace_period_allowed: true,
        bill_at: end_date,
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

  class Refund < Bill
    # Refunds must be a negative amount
    def check_amount
      raise InvalidBillingAmount, "Amount must be negative. It was #{amount.to_f}" if amount > 0
    end

    # Refunds are never considered "active"
    def active_during(date)
      false
    end

    def refunded_billing_attempt
      unless @refunded_billing_attempt
        if refunded_billing_attempt_id
          @refunded_billing_attempt = BillingAttempt.find(refunded_billing_attempt_id)
        end
      end
      @refunded_billing_attempt
    end

    def refunded_billing_attempt_id
      return metadata['refunded_billing_attempt_id'] if metadata
    end

    def refunded_billing_attempt=(billing_attempt)
      self.refunded_billing_attempt_id = billing_attempt.id
    end

    def refunded_billing_attempt_id=(id)
      if !metadata
        self.metadata = {}
      end
      metadata['refunded_billing_attempt_id'] = id
      @refunded_billing_attempt = nil
    end
  end
end
