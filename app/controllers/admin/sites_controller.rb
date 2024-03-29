class Admin::SitesController < AdminController
  before_action :calculate_views_avg, only: [:show]

  def show
    site
  end

  def update
    begin
      site.update_attributes(site_params) if params.key?(:site)
      change_subscription if params.key?(:subscription)
      flash[:success] = 'Site and/or subscription has been updated.'
    rescue PayBill::MissingCreditCard
      flash[:error] = 'Could not find a proper credit card'
    rescue Bill::InvalidBillingAmount => e
      flash[:error] = "You are trying to downgrade subscription but difference between subscriptions is #{ e.amount }$. Try to refund this amount first"
    rescue StandardError => e
      flash[:error] = "There was an error trying to update the subscription: #{ e.message }"
      raise if Rails.env.test?
    end

    redirect_to admin_site_path(params[:id])
  end

  def regenerate
    site = Site.find_by(id: params[:id])

    return render(json: { message: 'Site was not found' }, status: 404) if site.nil?

    begin
      site.touch # refresh cache
      GenerateAndStoreStaticScript.new(site).call
      render json: { message: 'Site regenerated' }, status: 200
    rescue RuntimeError
      render json: { message: "Site's script failed to generate" }, status: 500
    end
  end

  def add_free_days
    AddFreeDays.new(site, params[:free_days][:count]).call
    flash[:success] = "#{ params[:free_days][:count] } free days have been added."
    redirect_to admin_site_path(params[:id])
  rescue AddFreeDays::Error => e
    flash[:error] = e.message
    redirect_to admin_site_path(params[:id])
  end

  def destroy
    DestroySite.new(site).call
    flash[:success] = 'This site has been successfully deleted'

    redirect_to admin_site_path(params[:id])
  end

  private

  def calculate_views_avg
    @stats = FetchSiteStatistics.new(site, days_limit: 30).call
  end

  def change_subscription
    if subscription_params[:trial_period].present?
      AddFreeDaysOrTrialSubscription.new(
        site,
        subscription_params[:trial_period],
        subscription: subscription_params[:subscription]
      ).call
    else
      ChangeSubscription.new(site, subscription_params, site.credit_cards.last).call
    end
  end

  def subscription_params
    params.require(:subscription).permit(:subscription, :schedule, :trial_period)
  end

  def site_params
    params.require(:site).permit(:id, :url, :opted_in_to_email_digest, :timezone, :invoice_information)
  end

  def site
    @site ||= Site.with_deleted.find(params[:id])
  end
end
