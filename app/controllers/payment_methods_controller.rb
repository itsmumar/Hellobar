class PaymentMethodsController < ApplicationController
  include Subscribable

  before_action :authenticate_user!

  # returns all of the payment methods for the current user
  def index
    load_site if params[:site_id] # not required for this action

    payment_methods = current_user.payment_methods.includes(:details)
    subscription_payment_method_id = @site.current_subscription.payment_method_id if @site

    payment_response = payment_methods.map do |method|
      PaymentMethodSerializer.new(method).to_hash.tap do |hash|
        hash[:current_site_payment_method] = hash[:id] == subscription_payment_method_id
      end
    end

    respond_to do |format|
      format.json { render json: payment_response }
    end
  end

  # creating a new payment method and payment detail
  def create
    load_site

    unless Permissions.view_bills?(current_user, @site)
      respond_to do |format|
        format.json { render json: { errors: ['Contact the account owner to upgrade this site.'] }, status: :unprocessable_entity }
      end
      return
    end

    old_subscription = @site.current_subscription
    payment_method = PaymentMethod.new user: current_user
    payment_method_details = CyberSourceCreditCard.new \
      payment_method: payment_method,
      data: PaymentForm.new(params[:payment_method_details]).to_hash

    if payment_method_details.save && payment_method.save
      payment_method.reload # reload so #current_details can be loaded properly
      changed_subscription = subscription_bill_and_status(@site, payment_method, params[:billing], old_subscription)

      respond_to do |format|
        format.json { render json: changed_subscription }
      end
    else # invalid payment info
      respond_to do |format|
        format.json { render json: { errors: payment_method_details.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # updating the details of their CC or linking existing payment detail
  def update
    load_site

    old_subscription = @site.current_subscription
    payment_method = current_user.payment_methods.find params[:id]
    process_subscription = true

    # they are updating their current payment details
    if params[:payment_method_details]
      payment_method_details = CyberSourceCreditCard.new \
        payment_method: payment_method,
        data: PaymentForm.new(params[:payment_method_details]).to_hash

      process_subscription = payment_method_details.save
    end

    if process_subscription
      respond_to do |format|
        result = subscription_bill_and_status(@site, payment_method, params[:billing], old_subscription)
        status = result.delete(:status) || :ok
        format.json { render json: result, status: status }
      end
    else # invalid payment info
      respond_to do |format|
        format.json { render json: { errors: payment_method_details.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end
end
