require 'billing_log'

class BillingAttempt < ActiveRecord::Base
  class InvalidRefund < RuntimeError; end
  belongs_to :bill
  belongs_to :payment_method_details
  enum status: %i[success failed]
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

  def process!
    success = response = nil
    if bill.amount >= 0
      success, response = payment_method_details.charge(bill.amount)
      bill.update_column(:authorization_code, response)
    else
      # Make sure we use the same payment method details as the refunded attempt
      self.payment_method_details = bill.refunded_billing_attempt.payment_method_details
      success, response = payment_method_details.refund(-bill.amount, bill.refunded_billing_attempt.response)
    end
    self.status = success ? :success : :failed
    self.response = response
    save!
    if success?
      audit << "Attempt was successful, marking Bill[#{ bill.id }] as paid with response #{ response.inspect }"
      bill.paid!
    else
      audit << "Attempt was not successful (#{ response.inspect }) - not changing Bill[#{ bill.id }] status"
    end
    self
  end

  alias orig_status status
  def status
    orig_status.to_sym
  end

  def success?
    status == :success
  end
  alias successful? success?
end
