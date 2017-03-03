require 'billing_log'

class BillingAttempt < ActiveRecord::Base
  class InvalidRefund < Exception; end
  belongs_to :bill
  belongs_to :payment_method_details
  enum status: [:success, :failed]
  include BillingAuditTrail
  delegate :subscription, to: :bill
  delegate :subscription_id, to: :bill
  delegate :payment_method, to: :payment_method_details
  delegate :payment_method_id, to: :payment_method_details
  delegate :user, to: :payment_method_details
  delegate :user_id, to: :payment_method_details
  delegate :site, to: :bill
  delegate :site_id, to: :bill

  def readonly?
    new_record? ? false : true
  end

  # Can optionally specify a partial amount or description
  def refund!(description = nil, amount = nil)
    raise InvalidRefund.new('Can not refund unsuccessful billing attempt') unless self.success?
    amount ||= self.bill.amount
    amount = amount.abs * -1 # Refunds are always negative

    # Check that we're not refunding more than they paid
    previous_refunds = self.bill.subscription.bills.select { |x| x.is_a?(Bill::Refund) && x.refunded_billing_attempt_id == id }.map(&:amount).sum
    raise InvalidRefund.new('Cannot refund more than than the amount paid') if self.bill.amount + (amount + previous_refunds) < 0

    description ||= 'Refund due to customer service request'
    now = Time.now
    refund_bill = Bill::Refund.new(
      subscription: self.bill.subscription,
      amount: amount,
      description: description,
      bill_at: now,
      start_date: now,
      end_date: self.bill.end_date,
      refunded_billing_attempt: self
    )
    refund_attempt = refund_bill.attempt_billing!
    refund_bill.save!

    return refund_bill, refund_attempt
  end

  def process!
    success = response = nil
    if bill.amount >= 0
      success, response = payment_method_details.charge(bill.amount)
    else
      # Make sure we use the same payment method details as the refunded attempt
      self.payment_method_details = bill.refunded_billing_attempt.payment_method_details
      success, response = payment_method_details.refund(-bill.amount, bill.refunded_billing_attempt.response)
    end
    self.status = success ? :success : :failed
    self.response = response
    self.save!
    if success?
      audit << "Attempt was successful, marking Bill[#{bill.id}] as paid with response #{response.inspect}"
      bill.paid!
    else
      audit << "Attempt was not successful (#{response.inspect}) - not changing Bill[#{bill.id}] status"
    end
    return self
  end

  alias :orig_status :status
  def status
    orig_status.to_sym
  end

  def success?
    status == :success
  end
  alias :successful? :success?
end
