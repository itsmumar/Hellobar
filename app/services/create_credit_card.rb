class CreateCreditCard
  def initialize(site, user, params)
    @site = site
    @user = user
    @form = PaymentForm.new(params[:credit_card])
    @update_subscription = params[:update_subscription]
  end

  def call
    validate_form!
    create_credit_card.tap do |credit_card|
      site.current_subscription.update(credit_card_id: credit_card.id) if update_subscription && site&.current_subscription
      track_event(credit_card)
    end
  end

  private

  attr_reader :site, :user, :form, :update_subscription

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
    CreateCreditCardAtCyberSource.new(user, form.card, params).call
  rescue StandardError => e
    credit_card.errors.add :base, e.message
    raise ActiveRecord::RecordInvalid, credit_card
  end

  # we don't want to give CyberSource our customer's email addresses,
  # which is why we use the generic userXXX@hellobar.com format
  def email_for_cybersource
    "user#{ user&.id || 'NA' }@hellobar.com"
  end

  def track_event(credit_card)
    TrackEvent.new(
      :added_credit_card,
      user: credit_card.user,
      site: site
    ).call
  end
end
