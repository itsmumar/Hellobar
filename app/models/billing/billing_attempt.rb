class BillingAttempt < ActiveRecord::Base
  belongs_to :bill
  belongs_to :payment_method_details
  has_one :payment_method, through: :payment_method_details
  has_one :user, through: :payment_method
  has_one :subscription, through: :bill
  has_one :site, through: :bill
  has_many :refunds, foreign_key: 'refunded_billing_attempt_id', class_name: 'Bill::Refund'

  enum status: %i[success failed]

  def readonly?
    new_record? ? false : true
  end

  def status
    super.to_sym
  end
end
