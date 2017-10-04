class PaymentMethodDetails < ActiveRecord::Base
  self.inheritance_column = '_type'
  has_many :billing_attempts, dependent: :destroy
  has_one :user, through: :payment_method, dependent: :destroy
  has_one :credit_card, foreign_key: :details_id, dependent: :nullify
  belongs_to :payment_method

  serialize :data, JSON

  def token
    data['token']
  end
end
