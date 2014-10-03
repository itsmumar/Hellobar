require 'billing_log'
class PaymentMethod < ActiveRecord::Base
  class MissingPaymentDetails < Exception; end
  belongs_to :user
  has_many :details, -> {order 'id'}, :class_name => "PaymentMethodDetails"
  has_many :subscriptions
  acts_as_paranoid
  include BillingAuditTrail

  def current_details
    self.details.last
  end

  def name
    current_details ? current_details.name : nil
  end

  def pay(bill)
    raise MissingPaymentDetails.new("Can not pay bill without payment method details") unless current_details
    BillingAttempt.new(bill: bill, payment_method_details: current_details).process!
  end
end
