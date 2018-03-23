class SubscriptionsController < ApplicationController
  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid

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

  # updates subscription
  def update
    load_site

    credit_card = current_user.credit_cards.find params[:credit_card_id]
    changed_subscription = change_subscription(credit_card)

    respond_to do |format|
      format.json { render json: changed_subscription }
    end
  end

  private

  def record_invalid(e)
    respond_to do |format|
      format.json do
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def change_subscription(credit_card)
    bill = ChangeSubscription.new(@site, params[:billing], credit_card).call
    BillSerializer.new(bill)
  end
end
