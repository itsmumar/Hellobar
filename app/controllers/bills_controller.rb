class BillsController < ApplicationController
  before_action :authenticate_user!

  before_action :set_bill_and_site
  before_action :check_permissions
  before_action :dont_allow_probem_bill, only: :show

  def show
    @credit_card = @bill.paid_with_credit_card
    render layout: 'receipt'
  end

  def pay
    PayBill.new(@bill).call

    if @bill.problem?
      card = @bill.payment_method_detail
      flash[:alert] =
        "There was a problem while charging your credit card ending in #{ card.last_digits }. " \
        'You can fix this by adding another credit card'
      redirect_to edit_site_path(@bill.site, should_update_card: true, anchor: 'problem-bill')
    else
      flash[:success] = 'Your bill has been successfully paid. Thank you!'
      redirect_to site_path(@bill.site)
    end
  end

  private

  def set_bill_and_site
    @bill = Bill.find(params[:id])
    @site = Site.unscoped.find(@bill.site_id)
  end

  def check_permissions
    Permissions.view_bills?(current_user, @site) || raise(ActiveRecord::RecordNotFound)
  end

  def dont_allow_probem_bill
    @bill.problem? && raise(ActiveRecord::RecordNotFound)
  end
end
