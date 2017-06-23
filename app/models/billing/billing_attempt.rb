class BillingAttempt < ActiveRecord::Base
  belongs_to :bill
  belongs_to :payment_method_details
  has_one :payment_method, through: :payment_method_details
  has_one :user, through: :payment_method
  has_one :subscription, through: :bill
  has_one :site, through: :bill

  enum status: %i[success failed]

  delegate :id, to: :subscription, prefix: true, allow_nil: true
  delegate :id, to: :payment_method, prefix: true, allow_nil: true
  delegate :id, to: :user, prefix: true, allow_nil: true
  delegate :id, to: :bill, prefix: true, allow_nil: true
  delegate :id, to: :site, prefix: true, allow_nil: true

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
      success, response = payment_method_details.refund(-bill.amount, bill.refunded_bill.authorization_code)
    end
    self.status = success ? :success : :failed
    self.response = response
    save!
    if success?
      bill.paid!
      bill.create_next_bill! unless bill.is_a?(Bill::Refund)
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
