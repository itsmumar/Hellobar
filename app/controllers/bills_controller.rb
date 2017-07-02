class BillsController < ApplicationController
  before_action :authenticate_user!

  def show
    @bill = Bill.find(params[:id])
    @site = Site.unscoped.find(@bill.site_id)
    @details = @bill.successful_billing_attempt.try(:payment_method_details)
    raise ActiveRecord::RecordNotFound if !Permissions.view_bills?(current_user, @site) || @bill.problem?
    render layout: 'receipt'
  end
end
