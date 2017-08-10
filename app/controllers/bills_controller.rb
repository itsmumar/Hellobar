class BillsController < ApplicationController
  before_action :authenticate_user!

  def show
    @bill = Bill.find(params[:id])
    @site = Site.unscoped.find(@bill.site_id)
    @details = @bill.successful_billing_attempt.try(:payment_method_details)
    raise ActiveRecord::RecordNotFound if !Permissions.view_bills?(current_user, @site) || @bill.problem?
    render layout: 'receipt'
  end

  def pay
    bill = Bill.find(params[:id])
    PayBill.new(bill).call

    if bill.problem?
      card = bill.payment_method_detail
      flash[:alert] =
        "There was a problem charging your card #{ card.number }. Try to use another one"
      redirect_to edit_site_path(bill.site)
    else
      flash[:success] = 'The bill has been successfully paid. Thank you!'
      redirect_to site_path(bill.site)
    end
  end
end
