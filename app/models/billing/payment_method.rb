class PaymentMethod < ActiveRecord::Base
  class MissingPaymentDetails < RuntimeError; end

  belongs_to :user
  has_many :details, -> { order 'id' }, class_name: 'PaymentMethodDetails'
  has_many :subscriptions

  acts_as_paranoid

  delegate :name, :charge, :refund, to: :current_details, allow_nil: true

  def current_details
    details.last
  end

  def pay(bill)
    raise MissingPaymentDetails, 'Can not pay bill without payment method details' unless current_details
    # HACK: ..
    # setting payment_method_details_id instead of the object to avoid
    # ActiveRecord::AssociationTypeMismatch error from being raised
    BillingAttempt.new(bill: bill, payment_method_details_id: current_details.id).process!
  end
end
