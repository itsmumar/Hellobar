class PaymentMethod < ActiveRecord::Base
  belongs_to :user
  enum status: [:active, :deleted]
  has_many :details, -> {order 'id'}, :class_name=>"PaymentMethodDetails"

  def current_details
    self.details.last
  end

  def name
    current_payment_details.name
  end
end
