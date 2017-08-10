class BillsController < ApplicationController
  before_action :authenticate_user!

  before_action :set_bill_and_site
  before_action :check_permissions
  before_action :dont_allow_probem_bill, only: :show

  def show
    @details = @bill.successful_billing_attempt.try(:payment_method_details)
    render layout: 'receipt'
  end

  def pay
    PayBill.new(@bill).call

    if @bill.problem?
      card = @bill.payment_method_detail
      flash[:alert] =
        "There was a problem charging your card #{ card.number }. Try to use another one"
      redirect_to edit_site_path(@bill.site)
    else
      flash[:success] = 'The bill has been successfully paid. Thank you!'
      redirect_to site_path(@bill.site)
    end
  end

  private

  def set_bill_and_site
    @bill = Bill.find(params[:id])
    @site = Site.unscoped.find(@bill.site_id)
  end

  def check_permissions
    if !Permissions.view_bills?(current_user, @site)
      raise ActiveRecord::RecordNotFound
    end
  end

  def dont_allow_probem_bill
    if @bill.problem?
      raise ActiveRecord::RecordNotFound
    end
  end
end
