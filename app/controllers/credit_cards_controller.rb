class CreditCardsController < ApplicationController
  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid

  def index
    load_site if params[:site_id] # not required for this action

    credit_cards = current_user.credit_cards
    subscription_credit_card_id = @site.current_subscription.credit_card_id if @site

    response = credit_cards.map do |credit_card|
      CreditCardSerializer.new(credit_card).to_hash.tap do |hash|
        hash[:current_site_credit_card] = hash[:id] == subscription_credit_card_id
      end
    end

    respond_to do |format|
      format.json { render json: response }
    end
  end

  # TODO: move it to SubscriptionController
  # creates a new credit card and updates subscription
  def create
    load_site

    unless Permissions.view_bills?(current_user, @site)
      respond_to do |format|
        format.json do
          render json: {
            errors: ['Contact the account owner to upgrade this site.']
          }, status: :unprocessable_entity
        end
      end
      return
    end

    credit_card = CreateCreditCard.new(@site, current_user, params).call
    changed_subscription = change_subscription(credit_card)

    respond_to do |format|
      format.json { render json: changed_subscription }
    end
  end

  # TODO: move it to SubscriptionController
  # updates subscription
  def update
    load_site

    credit_card = current_user.credit_cards.find params[:id]
    changed_subscription = change_subscription(credit_card)

    respond_to do |format|
      format.json { render json: changed_subscription }
    end
  end

  private

  def record_invalid(e)
    respond_to do |format|
      format.json { render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity }
    end
  end

  def change_subscription(credit_card)
    bill = ChangeSubscription.new(@site, params[:billing], credit_card).call
    BillSerializer.new(bill).tap do |serializer|
      Analytics.track(*current_person_type_and_id, 'Upgraded') if serializer.upgrade?
    end
  end
end
