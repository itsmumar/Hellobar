class CyberSourceGateway < ActiveMerchant::Billing::CyberSourceGateway
  # this is a workaround for tesing declined credit cards
  # use this value in address field and card will be declined
  INVALID_ADDRESS_FOR_TESTING_PURPOSES = 'card-declined'.freeze

  def initialize
    super(
      login: Settings.cybersource_login,
      password: Settings.cybersource_password,
      ignore_avs: true
    )
  end

  # @param [Integer] amount_in_dollars
  def purchase(amount_in_dollars, credit_card)
    amount = amount_in_dollars.to_f * 100

    raise 'credit card token does not exist' if credit_card.token.blank?
    check_amount!(amount)

    if card_declined?(credit_card)
      decline_card
    else
      super(amount, credit_card.formatted_token, order_id: credit_card.order_id)
    end
  end

  # @param [Integer] amount_in_dollars
  def refund(amount_in_dollars, original_transaction_id)
    amount = amount_in_dollars.to_f * 100
    check_amount!(amount)

    raise 'Can not refund without original transaction ID' if original_transaction_id.blank?

    super(amount, original_transaction_id)
  end

  private

  def check_amount!(amount)
    raise ArgumentError, "Invalid amount: #{ amount.inspect }" if amount.blank? || amount <= 0
  end

  ### for testing purposes

  def card_declined?(credit_card)
    credit_card.billing_address.address1 == INVALID_ADDRESS_FOR_TESTING_PURPOSES
  end

  def decline_card
    build_response(false, 'Decline - Insufficient funds in the account.')
  end

  def build_response(success, message)
    ActiveMerchant::Billing::Response.new(success, message, {}, test: test?)
  end
end
