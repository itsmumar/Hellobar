class Admin::SitesController < ApplicationController
  include Subscribable
  layout 'admin'

  before_action :require_admin

  def update
    begin
      site.update_attributes(site_params) if params.key?(:site)
      ChangeSubscription.new(site, subscription_params).call if params.key?(:subscription)
      flash[:success] = 'Site and/or subscription has been updated.'
    rescue PayBill::MissingPaymentMethod
      flash[:error] = 'You are trying to upgrade subscription but it must be paid by the user'
    rescue Bill::InvalidBillingAmount => e
      flash[:error] = "You are trying to downgrade subscription but difference between subscriptions is #{ e.amount }$. Try to refund this amount first"
    rescue => e
      flash[:error] = "There was an error trying to update the subscription: #{ e.message }"
      raise if Rails.env.test?
    end

    redirect_to admin_user_path(params[:user_id])
  end

  def regenerate
    site = Site.find_by(id: params[:id])

    if site.nil?
      return render(json: { message: 'Site was not found' }, status: 404)
    end

    begin
      GenerateAndStoreStaticScript.new(site).call
      render json: { message: 'Site regenerated' }, status: 200
    rescue RuntimeError
      render json: { message: "Site's script failed to generate" }, status: 500
    end
  end

  private

  def subscription_params
    params.require(:subscription).permit(:type, :schedule, :trial_period)
  end

  def site_params
    params.require(:site).permit(:id, :url, :opted_in_to_email_digest, :timezone, :invoice_information)
  end

  def site
    @site ||= Site.find(params[:id])
  end
end
