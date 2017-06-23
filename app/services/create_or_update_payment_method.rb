class CreateOrUpdatePaymentMethod
  def initialize(site, user, params, payment_method: nil)
    @site = site
    @user = user
    @params = params
    @payment_method = payment_method || PaymentMethod.new(user: user)
    @form = PaymentForm.new(params[:payment_method_details])
  end

  def call
    return payment_method if params[:payment_method_details].blank? && payment_method.persisted?

    validate_form!
    credit_card = create_credit_card
    save_to_cybersource(credit_card)
    credit_card.payment_method
  end

  private

  attr_reader :site, :user, :params, :form, :payment_method

  def validate_form!
    raise ActiveRecord::RecordInvalid, form unless form.valid?
  end

  def create_credit_card
    CyberSourceCreditCard.new(payment_method: payment_method, data: form.attributes)
  end

  def save_to_cybersource(credit_card)
    params = {
      order_id: credit_card.order_id,
      email: email_for_cybersource,
      address: credit_card.address.to_h
    }

    credit_card.token = create_or_update_card(params)
    credit_card.save!
  rescue => e
    credit_card.errors.add :base, e.message
    raise ActiveRecord::RecordInvalid, credit_card
  end

  def create_or_update_card(params)
    response = store_or_update_request(params)
    return response.params['subscriptionID'] if response.success?

    if (field = response.params['invalidField'])
      raise 'Invalid credit card' if field == 'c:cardType'
      raise "Invalid #{ field.gsub(/^c:/, '').underscore.humanize.downcase }"
    end
    raise response.message
  end

  def store_or_update_request(params)
    if previous_token
      # Update the profile
      gateway.update(format_token(previous_token), form.card, params)
    else
      # Create a new profile
      gateway.store(form.card, params)
    end
  end

  def previous_token
    @previous_token ||= previous_payment_method_details&.token
  end

  def previous_payment_method_details
    user.payment_method_details.where(type: 'CyberSourceCreditCard').find do |details|
      details.token.presence
    end
  end

  def format_token(token)
    ";#{ token };"
  end

  # we don't want to give CyberSource our customer's email addresses,
  # which is why we use the generic userXXX@hellobar.com format
  def email_for_cybersource
    "user#{ user&.id || 'NA' }@hellobar.com"
  end

  def gateway
    @gateway ||=
      ActiveMerchant::Billing::CyberSourceGateway.new(
        login: Settings.cybersource_login,
        password: Settings.cybersource_password,
        ignore_avs: true
      )
  end
end
