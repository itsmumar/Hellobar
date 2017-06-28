class PaymentMethodsController < ApplicationController
  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid

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

    payment_method = CreateOrUpdatePaymentMethod.new(@site, current_user, params).call
    changed_subscription = change_subscription(payment_method)

    respond_to do |format|
      format.json { render json: changed_subscription }
    end
  end

  # updating the details of their CC or linking existing payment detail
  def update
    load_site

    payment_method = current_user.payment_methods.find params[:id]
    payment_method = CreateOrUpdatePaymentMethod.new(@site, current_user, params, payment_method: payment_method).call
    changed_subscription = change_subscription(payment_method)

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

  # TODO: move it to a serializer
  def change_subscription(payment_method)
    bill = ChangeSubscription.new(@site, params[:billing], payment_method).call
    BillSerializer.new(bill).tap do |serializer|
      Analytics.track(*current_person_type_and_id, 'Upgraded') if serializer.upgrade?
    end
  end
end
