class CreditCardsController < ApplicationController
  before_action :authenticate_user!

  def index
    load_site if params[:site_id] # not required for this action
    subscription_credit_card_id = @site.current_subscription.credit_card_id if @site

    response = {
      credit_cards: current_user.credit_cards.map { |credit_card| CreditCardSerializer.new(credit_card).as_json },
      current_credit_card_id: subscription_credit_card_id
    }

    respond_to do |format|
      format.json { render json: response }
    end
  end
end
