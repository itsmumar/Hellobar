class PaymentMethodsController < ApplicationController
  include Subscribable

  before_action :authenticate_user!
  before_action :load_site

  # creating a new payment method and payment detail
  def create
    payment_method = PaymentMethod.new user: current_user
    payment_method_details = CyberSourceCreditCard.new \
      payment_method: payment_method,
      data: PaymentForm.new(params[:payment_method_details]).to_hash

    if payment_method_details.save && payment_method.save
      payment_method.reload # reload so #current_details can be loaded properly

      respond_to do |format|
        format.json { render json: subscription_bill_and_status(@site, payment_method, params[:billing]) } # subscribe renders appropriate object and status
      end
    else # invalid payment info
      respond_to do |format|
        format.json { render json: { errors: payment_method_details.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # updating the details of their CC or linking existing payment detail
  def update
    payment_method = current_user.payment_methods.find params[:id]

    # use an existing payment method for this site
    if params[:payment_method_details] && params[:payment_method_details][:linked_detail_id].present?
      process_subscription = true
    elsif params[:payment_method_details] # update payment details on existing payment method
      payment_method_details = CyberSourceCreditCard.new \
        payment_method: payment_method,
        data: PaymentForm.new(params[:payment_method_details]).to_hash

      process_subscription = payment_method_details.save
    else # they are linking an existing payment method to the subscription
      payment_method_details = payment_method.current_details

      process_subscription = payment_method_details.save
    end

    if process_subscription
      respond_to do |format|
        format.json { render json: subscription_bill_and_status(@site, payment_method, params[:billing]) } # subscribe renders appropriate object and status
      end
    else # invalid payment info
      respond_to do |format|
        format.json { render json: { errors: payment_method_details.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def load_site
    @site = current_user.sites.find params[:site_id]
  end
end
