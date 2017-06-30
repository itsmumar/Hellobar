class CyberSourceGateway < ActiveMerchant::Billing::CyberSourceGateway
  # this is a workaround for tesing declined redit cards
  # use this value in address field and card will be declined
  INVALID_ADDRESS_FOR_TESTING_PURPOSE = 'card-declined'.freeze

  def initialize
    super(
      login: Settings.cybersource_login,
      password: Settings.cybersource_password,
      ignore_avs: true
    )
  end

  def purchase(amount, credit_card)
    raise 'credit card token does not exist' if credit_card.token.blank?
    check_amount!(amount)

    if card_declined_test?(credit_card)
      card_declined
    else
      super(amount, credit_card.formatted_token, order_id: credit_card.order_id)
    end
  end

  def refund(amount, original_transaction_id)
    check_amount!(amount)

    if original_transaction_id.blank?
      raise 'Can not refund without original transaction ID'
    end

    response = super(amount, original_transaction_id)
    return false, response.message unless response.success?

    [true, response.authorization]
  end

  private

  def check_amount!(amount)
    raise ArgumentError, "Invalid amount: #{ amount.inspect }" if amount.blank? || amount <= 0
  end

  ### for testing purpose

  def card_declined_test?(credit_card)
    credit_card.address.address1 == INVALID_ADDRESS_FOR_TESTING_PURPOSE
  end

  def card_declined
    make_response(false, 'Decline - Insufficient funds in the account.')
  end

  def make_response(success, message)
    ActiveMerchant::Billing::Response.new(success, message, {}, test: test?)
  end
end
