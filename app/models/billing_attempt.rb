require 'billing_log'

class BillingAttempt < ActiveRecord::Base
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

  def process!
    success, response = payment_method_details.charge(bill.amount)
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
end
