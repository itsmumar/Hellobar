class CreditCard < ActiveRecord::Base
  include ActiveMerchant::Billing::CreditCardMethods

  belongs_to :user
  has_many :subscriptions
  has_many :billing_attempts

  acts_as_paranoid

  validates :number, :last_digits, :month, :year, :first_name, :last_name, :brand, presence: true
  validates :city, :zip, :address, :country, presence: true
  validates :state, presence: true, if: -> { country == 'US' }
  validates :token, presence: true#, uniqueness: true

  Address = Struct.new(:zip, :address, :city, :state, :country, :address1)
  composed_of :billing_address, class_name: 'CreditCard::Address', mapping: [
    %w[zip zip], %w[address address], %w[city city], %w[state state], %w[country country], %w[address address1]
  ]

  def number=(value)
    self[:number] = self.class.mask(value)
  end

  def last_digits
    self.class.last_digits number if number.present?
  end

  def grace_period
    15.days
  end

  def refund(amount_in_dollars, original_transaction_id)
    response = gateway.refund(amount_in_dollars.to_f * 100, original_transaction_id)

    return false, response.message unless response.success?
    [true, response.authorization]
  end

  def charge(amount_in_dollars)
    response = gateway.purchase(amount_in_dollars.to_f * 100, self)

    return false, response.message unless response.success?
    [true, response.authorization]
  end

  def delete_token
    return if token.blank?
    update_columns data: data.merge('token' => nil)
  end

  def order_id
    # The order_id is fairly irrelevant
    "#{ id || 'NA' }-#{ Time.current.to_i }"
  end

  # ActiveMerchant requires the token in this form
  def formatted_token
    ";#{ token };"
  end

  private

  def gateway
    @gateway ||= CyberSourceGateway.new
  end
end
