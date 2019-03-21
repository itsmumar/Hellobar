class SubscriptionsController < ApplicationController
  before_action :load_site, only: :create
  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid

  def create
    InitializeStripeAndSubscribe.new(charges_params, current_user, @site).call

    respond_to do |format|
      format.json do
        render json: current_site.current_subscription, serializer: SubscriptionSerializer
      end
      format.html do
        redirect_to root_path
      end
    end
  end

  # updates subscription
  def update
    load_site

    credit_card = current_user.credit_cards.find params[:credit_card_id]
    same_subscription, bill = change_subscription(credit_card)

    respond_to do |format|
      format.json do
        render json: bill, serializer: BillSerializer, scope: { same_subscription: same_subscription }
      end
    end
  end

  private

  def charges_params
    params.permit(:stripeToken, :plan, :schedule)
  end

  def change_subscription(credit_card)
    subscription_service = ChangeSubscription.new(@site, params[:billing], credit_card)
    [subscription_service.same_subscription?, subscription_service.call]
  end
end
