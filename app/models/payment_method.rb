class PaymentMethod < ActiveRecord::Base
  belongs_to :user
  has_many :details, -> {order 'id'}, :class_name=>"PaymentMethodDetails"
  acts_as_paranoid

  def current_details
    self.details.last
  end

  def name
    current_payment_details ? current_payment_details.name : nil
  end
end
