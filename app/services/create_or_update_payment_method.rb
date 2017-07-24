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
    credit_card.save!
    user.credit_cards.create!(form.attributes.merge(token: credit_card.token))
    credit_card.payment_method
  end

  private

  attr_reader :site, :params, :user, :form, :payment_method

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
    credit_card.token = SaveCardToCyberSource.new(user, form.card, params).call
  rescue => e
    credit_card.errors.add :base, e.message
    raise ActiveRecord::RecordInvalid, credit_card
  end

  # we don't want to give CyberSource our customer's email addresses,
  # which is why we use the generic userXXX@hellobar.com format
  def email_for_cybersource
    "user#{ user&.id || 'NA' }@hellobar.com"
  end
end
