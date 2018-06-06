class CreditCardsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_site

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

  def create
    credit_card = CreateCreditCard.new(@site, current_user, params).call
    render json: credit_card
  end
end
