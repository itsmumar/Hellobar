class CreateCreditCardAtCyberSource
  # @param [User] user
  # @param [ActiveMerchant::Billing::CreditCard] credit_card
  # @param [Hash] params; keys: order_id, email, address
  def initialize(user, credit_card, params)
    @user = user
    @credit_card = credit_card
    @params = params
  end

  def call
    response = create_profile
    BillingLogger.credit_card(user.sites.first, response)
    handle_errors(response) unless response.success?

    response.params['subscriptionID']
  end

  private

  attr_reader :user, :credit_card, :params

  def handle_errors(response)
    if (field = response.params['invalidField'])
      raise 'Invalid credit card' if field == 'c:cardType'
      raise "Invalid #{ field.gsub(/^c:/, '').underscore.humanize.downcase }"
    end
    raise response.message
  end

  def create_profile
    gateway.store(credit_card, params)
  end

  def gateway
    @gateway ||= CyberSourceGateway.new
  end
end
