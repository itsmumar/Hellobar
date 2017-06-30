class CyberSourceCreditCard < PaymentMethodDetails
  class BillingAddress < OpenStruct
  end

  CC_FIELDS = %w[number month year first_name last_name brand].freeze
  ADDRESS_FIELDS = %w[city state zip address country].freeze
  # Note: any fields not included here will be stripped out when setting
  FIELDS = CC_FIELDS + ADDRESS_FIELDS + ['token']

  validates :token, :last_digits, presence: true

  store :data, accessors: %i[number token brand], coder: JSON

  delegate :refund, to: :gateway

  def grace_period
    15.days
  end

  def last_digits
    ActiveMerchant::Billing::CreditCard.last_digits number.gsub(/[^\d]/, '') if number.present?
  end

  def address
    @address ||=
      begin
        attributes = data.slice(*ADDRESS_FIELDS).symbolize_keys
        attributes[:address1] = attributes.delete(:address)
        BillingAddress.new(attributes)
      end
  end

  def data=(new_data)
    data = new_data.stringify_keys.slice(*FIELDS)
    data['number'] = ActiveMerchant::Billing::CreditCard.mask(data['number'])
    self[:data] = data
  end

  def charge(amount_in_dollars)
    raise 'credit card token does not exist' if token.blank?
    gateway.charge amount_in_dollars, self
  end

  def delete_token
    return if token.blank?
    update_columns data: data.merge('token' => nil)
  end

  def order_id
    # The order_id is fairly irrelevant
    "#{ payment_method&.id || 'NA' }-#{ Time.current.to_i }"
  end

  # ActiveMerchant requires the token in this form
  def formatted_token
    format_token(token)
  end

  protected

  def format_token(token)
    ";#{ token };"
  end

  private

  def gateway
    @gateway ||= CyberSourceGateway.new
  end
end
