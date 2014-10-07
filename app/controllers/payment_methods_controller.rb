class PaymentMethodsController < ApplicationController
  include Subscribable

  before_action :authenticate_user!
  before_action :load_site

  def create
    payment_method = PaymentMethod.new user: current_user
    payment_method_details = CyberSourceCreditCard.new \
      payment_method: payment_method,
      data: PaymentForm.new(params[:payment_method_details]).to_hash

    if payment_method_details.save && payment_method.save
      respond_to do |format|
        format.json { render json: subscription_bill_and_status(@site, payment_method, params[:billing]) } # subscribe renders appropriate object and status
      end
    else # invalid payment info
      respond_to do |format|
        format.json { render json: { errors: payment_method_details.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    payment_method = current_user.payment_methods.find params[:id]
    payment_method_details = CyberSourceCreditCard.new \
      payment_method: payment_method,
      data: PaymentForm.new(params[:payment_method_details]).to_hash

    if payment_method_details.save
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
