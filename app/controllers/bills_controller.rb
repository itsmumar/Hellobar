class BillsController < ApplicationController
  before_action :authenticate_user!

  before_action :set_bill_site_subscription
  before_action :check_permissions
  before_action :dont_allow_probem_bill, only: :show

  def show
    @credit_card = @bill.paid_with_credit_card
    render layout: 'receipt'
  end

  def pay
    PayBill.new(@bill).call

    if @bill.failed?
      flash[:alert] =
        "There was a problem while charging your credit card ending in #{ @bill.subscription.credit_card.last_digits }. " \
        'You can fix this by adding another credit card'
      redirect_to edit_site_path(@bill.site, should_update_card: true, anchor: 'problem-bill')
    else
      flash[:success] = 'Your bill has been successfully paid. Thank you!'
      redirect_to site_path(@bill.site)
    end
  rescue PayBill::MissingCreditCard => e
    flash[:alert] = e.message
    redirect_to edit_site_path(@bill.site, should_update_card: true, anchor: 'problem-bill')
  end

  private

  def set_bill_site_subscription
    @bill = Bill.find(params[:id])
    @site = Site.unscoped.find(@bill.site_id)
    @subscription = @bill.subscription
  end

  def check_permissions
    Permissions.view_bills?(current_user, @site) || raise(ActiveRecord::RecordNotFound)
  end

  def dont_allow_probem_bill
    @bill.failed? && raise(ActiveRecord::RecordNotFound)
  end
end
