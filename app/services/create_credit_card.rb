class CreateCreditCard
  def initialize(site, user, params)
    @site = site
    @user = user
    @form = PaymentForm.new(params[:credit_card])
  end

  def call
    validate_form!
    create_credit_card
  end

  private

  attr_reader :site, :user, :form

  def validate_form!
    raise ActiveRecord::RecordInvalid, form unless form.valid?
  end

  def create_credit_card
    user.credit_cards.create!(form.attributes) do |credit_card|
      credit_card.token = save_to_cybersource(credit_card)
    end
  end

  def save_to_cybersource(credit_card)
    params = {
      order_id: credit_card.order_id,
      email: email_for_cybersource,
      address: credit_card.billing_address.to_h
    }
    SaveCardToCyberSource.new(user, form.card, params).call
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
