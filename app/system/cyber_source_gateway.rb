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

  def charge(amount_in_dollars, credit_card)
    return true, 'Amount was zero' if amount_in_dollars == 0

    if amount_in_dollars.blank? || amount_in_dollars < 0
      raise ArgumentError, "Invalid amount: #{ amount_in_dollars.inspect }"
    end

    response =
      if card_declined_test?(credit_card)
        card_declined
      else
        purchase(amount_in_dollars * 100, credit_card.formatted_token, order_id: credit_card.order_id)
      end

    [response.success?, response.authorization || response.message]
  end

  def refund(amount_in_dollars, original_transaction_id)
    return true, 'Amount was zero' if amount_in_dollars == 0

    if amount_in_dollars.blank? || amount_in_dollars < 0
      raise ArgumentError, "Invalid amount: #{ amount_in_dollars.inspect }"
    end

    if original_transaction_id.blank?
      raise 'Can not refund without original transaction ID'
    end

    response = gateway.refund(amount_in_dollars * 100, original_transaction_id)
    return false, response.message unless response.success?

    [true, response.authorization]
  end

  private

  ### for testing purpose

  def card_declined_test?(credit_card)
    credit_card.address.address1 == INVALID_ADDRESS_FOR_TESTING_PURPOSE
  end

  def card_declined
    ActiveMerchant::Billing::Response.new(
      false,
      'Decline - Insufficient funds in the account.',
      {},
      test: test?
    )
  end
end
