class CyberSourceCreditCard < PaymentMethodDetails
  class BillingAddress < OpenStruct
  end

  CC_FIELDS = %w[number month year first_name last_name brand].freeze
  ADDRESS_FIELDS = %w[city state zip address country].freeze
  # Note: any fields not included here will be stripped out when setting
  FIELDS = CC_FIELDS + ADDRESS_FIELDS + ['token']

  validates :token, :last_digits, presence: true

  store :data, accessors: %i[number token]

  def name
    "#{ brand&.capitalize || 'Credit Card' } ending in #{ last_digits.presence || '???' }"
  end

  def grace_period
    15.days
  end

  def last_digits
    ActiveMerchant::Billing::CreditCard.last_digits number.gsub(/[^\d]/, '') if number.present?
  end

  def brand
    data['brand']
  end

  def address
    @address ||=
      begin
        attributes = ADDRESS_FIELDS.inject({}) { |hash, key| hash.update key.to_sym => data[key] }
        attributes[:address1] = attributes.delete(:address)
        BillingAddress.new(attributes)
      end
  end

  def data=(new_data)
    data = new_data.stringify_keys.select { |key| FIELDS.include?(key) }
    data['number'] = ActiveMerchant::Billing::CreditCard.mask(data['number'])
    self[:data] = data
  end

  def charge(amount_in_dollars)
    raise 'credit card token does not exist' if token.blank?
    return true, 'Amount was zero' if amount_in_dollars == 0

    if amount_in_dollars.blank? || amount_in_dollars < 0
      raise ArgumentError, "Invalid amount: #{ amount_in_dollars.inspect }"
    end

    response = gateway.purchase(amount_in_dollars * 100, formatted_token, order_id: order_id)
    audit << "Charging #{ amount_in_dollars.inspect }, got response: #{ response.inspect }"
    return false, response.message unless response.success?

    [true, response.authorization]
  rescue => e
    audit << "Error charging #{ amount_in_dollars.inspect }: #{ e.message }"
    raise
  end

  def refund(amount_in_dollars, original_transaction_id)
    raise 'Can not refund money until saved' unless persisted? && token
    return true, 'Amount was zero' if amount_in_dollars == 0

    if amount_in_dollars.blank? || amount_in_dollars < 0
      raise ArgumentError, "Invalid amount: #{ amount_in_dollars.inspect }"
    end

    if original_transaction_id.blank?
      raise 'Can not refund without original transaction ID'
    end

    response = gateway.refund(amount_in_dollars * 100, original_transaction_id)
    audit << "Refunding #{ amount_in_dollars.inspect } to #{ original_transaction_id.inspect }, got response: #{ response.inspect }"
    return false, response.message unless response.success?

    [true, response.authorization]
  rescue => e
    audit << "Error refunding #{ amount_in_dollars.inspect } to #{ original_transaction_id.inspect }: #{ e.message }"
    raise
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
    @gateway ||=
      ActiveMerchant::Billing::CyberSourceGateway.new(
        login: Settings.cybersource_login,
        password: Settings.cybersource_password,
        ignore_avs: true
      )
  end
end
