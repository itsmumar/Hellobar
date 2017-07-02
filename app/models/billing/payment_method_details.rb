class PaymentMethodDetails < ActiveRecord::Base
  belongs_to :payment_method
  has_many :billing_attempts
  has_one :user, through: :payment_method

  serialize :data, JSON

  def readonly?
    new_record? ? false : true
  end

  def grace_period
    nil
  end
end
