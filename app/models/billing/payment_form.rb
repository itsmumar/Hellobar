# breaks up user input to be used by a PaymentMethodDetail instance
class PaymentForm
  include ActiveModel::Model

  attr_accessor :number, :expiration, :verification_value
  attr_accessor :name, :city, :state, :zip, :address, :country
  attr_reader :first_name, :last_name

  validates :number, :expiration, :month, :year, :name, :city, :zip, :address, :country, :verification_value, presence: true
  validates :state, presence: true, if: -> { country == 'US' }

  validate do
    errors.add(:number, :invalid) if brand.blank? && number.present?
    errors.add(:base, 'Card has expired') if expiration.present? && card.expired?
    errors.add(:name, 'must contain first and last names') if name.present? && (first_name.blank? || last_name.blank?)
  end

  delegate :brand, to: :card

  def initialize(params = {})
    super
    normalize!
  end

  def normalize!
    @number = @number.to_s.delete(' ')
    @first_name, @last_name = (name || '').split(' ', 2)
    @month, @year = (expiration || '').split('/', 2)
  end

  def month
    return unless @month
    @month.to_i
  end

  def year
    return unless @year

    case @year.length
    when 2
      2000 + @year.to_i
    when 4
      @year.to_i
    end
  end

  def card
    ActiveMerchant::Billing::CreditCard.new(credit_card_params)
  end

  def address_attributes
    {
      country: country,
      city: city,
      state: state,
      address1: address,
      zip: zip
    }
  end

  def sanitized_number
    return if number.blank?
    card.display_number
  end

  def attributes
    {
      number: sanitized_number,
      month: month,
      year: year,
      brand: brand,
      first_name: first_name,
      last_name: last_name,
      city: city,
      state: state,
      zip: zip,
      address: address,
      country: country
    }
  end

  private

  def credit_card_params
    {
      number: number,
      month: month,
      year: year,
      first_name: first_name,
      last_name: last_name,
      verification_value: verification_value
    }
  end
end
