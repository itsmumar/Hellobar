class CreditCardsController < ApplicationController
  before_action :authenticate_user!

  def index
    load_site if params[:site_id] # not required for this action

    credit_cards = current_user.credit_cards
    subscription_credit_card_id = @site.current_subscription.credit_card_id if @site

    response = credit_cards.map do |credit_card|
      CreditCardSerializer.new(credit_card).serializable_hash.tap do |hash|
        hash[:current_site_credit_card] = hash[:id] == subscription_credit_card_id
      end
    end

    respond_to do |format|
      format.json { render json: response }
    end
  end
end
