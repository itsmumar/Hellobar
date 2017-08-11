class PaymentMethodDetails < ActiveRecord::Base
  has_many :billing_attempts
  has_one :user, through: :payment_method
  has_one :credit_card, foreign_key: :details_id, dependent: :nullify

  serialize :data, JSON

  def grace_period
    nil
  end
end
