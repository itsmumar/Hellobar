class CreditCardsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_site
  before_action :load_partner_plan, only: %i[new create]
  skip_before_action :require_credit_card

  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid

  def index
    subscription_credit_card_id = @site.current_subscription.credit_card_id if @site

    response = {
      credit_cards: current_user.credit_cards.map { |credit_card| CreditCardSerializer.new(credit_card).as_json },
      current_credit_card_id: subscription_credit_card_id
    }

    respond_to do |format|
      format.json { render json: response }
    end
  end

  def new
    @form = PaymentForm.new(params[:credit_card])

    render layout: 'static'
  end

  def create
    @form = PaymentForm.new(params[:credit_card])
    credit_card = CreateCreditCard.new(@site, current_user, params).call

    respond_to do |format|
      format.html { redirect_to after_sign_in_path_for(current_user) }
      format.json { render json: credit_card }
    end
  end

  private

  def record_invalid(error)
    respond_to do |format|
      format.html do
        flash.now[:error] = error.record.errors.full_messages.to_sentence
        render :new, layout: 'static'
      end
      format.json do
        Raven.capture_exception(error.record.errors.full_messages.to_sentence, extra: { full_response: error.record.errors.full_messages })
        render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def load_partner_plan
    @partner_plan = current_user.affiliate_information&.partner&.partner_plan
  end
end
