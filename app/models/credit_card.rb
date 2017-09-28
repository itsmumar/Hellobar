class CreditCard < ActiveRecord::Base
  include ActiveMerchant::Billing::CreditCardMethods

  belongs_to :user
  has_many :subscriptions
  has_many :billing_attempts

  validates :number, :last_digits, :month, :year, :first_name, :last_name, :brand, presence: true
  validates :city, :zip, :address, :country, presence: true
  validates :state, presence: true, if: -> { country == 'US' }
  validates :number, format: { with: /\A(XXXX-){3}(\d{2,4})\Z/ }

  Address = Struct.new(:zip, :address, :city, :state, :country, :address1) # address1 is needed for ActiveMerchant
  composed_of :billing_address, class_name: 'CreditCard::Address', mapping: [
    %w[zip zip], %w[address address], %w[city city], %w[state state], %w[country country], %w[address address1]
  ]

  def name
    "#{ first_name } #{ last_name }"
  end

  def description
    "#{ brand.capitalize } ending in #{ last_digits }"
  end

  def number=(value)
    self[:number] = self.class.mask(value).strip
  end

  def last_digits
    self.class.last_digits number if number.present?
  end

  def grace_period
    15.days
  end

  # The order_id is fairly irrelevant
  def order_id
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
