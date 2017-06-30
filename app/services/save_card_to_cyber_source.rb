class SaveCardToCyberSource
  # @param [User] user
  # @param [ActiveMerchant::Billing::CreditCard] credit_card
  # @param [Hash] params; keys: order_id, email, address
  def initialize(user, credit_card, params)
    @user = user
    @credit_card = credit_card
    @params = params
  end

  def call
    response = create_or_update_profile
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

  def create_or_update_profile
    if previous_token
      update_profile
    else
      create_profile
    end
  end

  def update_profile
    gateway.update(previous_token, credit_card, params)
  end

  def create_profile
    gateway.store(credit_card, params)
  end

  def previous_token
    @previous_token ||= previous_payment_method_details&.formatted_token
  end

  def previous_payment_method_details
    user.payment_method_details.where(type: 'CyberSourceCreditCard').find do |details|
      details.token.presence
    end
  end

  def gateway
    @gateway ||= CyberSourceGateway.new
  end
end
