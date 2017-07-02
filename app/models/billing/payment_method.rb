class PaymentMethod < ActiveRecord::Base
  belongs_to :user
  has_many :details, -> { order 'id' }, class_name: 'PaymentMethodDetails'
  has_many :subscriptions

  acts_as_paranoid

  delegate :name, :charge, :refund, to: :current_details, allow_nil: true

  def current_details
    details.last
  end
end
