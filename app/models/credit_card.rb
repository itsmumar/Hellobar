class CreditCard < ApplicationRecord
  include ActiveMerchant::Billing::CreditCardMethods

  belongs_to :user
  has_many :subscriptions, dependent: :nullify, inverse_of: :credit_card
  has_many :billing_attempts, inverse_of: :credit_card

  acts_as_paranoid

  validates :number, :last_digits, :month, :year, :first_name, :last_name, :brand, presence: true, if: -> { !stripe? }
  validates :city, :zip, :address, :country, presence: true, if: -> { !stripe? }
  validates :state, presence: true, if: -> { country == 'US' && !stripe? }
  validates :number, format: { with: /\A(XXXX-){3}(\d{2,4})\Z/ }, if: -> { !stripe? }

  Address = Struct.new(:zip, :address, :city, :state, :country, :address1) # address1 is needed for ActiveMerchant
  composed_of :billing_address, class_name: 'CreditCard::Address', mapping: [
    %w[zip zip], %w[address address], %w[city city], %w[state state], %w[country country], %w[address address1]
  ]

  def stripe?
    stripe_id.present?
  end

  def name
    "#{ first_name } #{ last_name }".strip
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
