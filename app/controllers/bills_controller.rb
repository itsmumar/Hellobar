class BillsController < ApplicationController
  before_action :authenticate_user!

  def show
    @bill = Bill.find(params[:id])
    @details = @bill.successful_billing_attempt.try(:payment_method_details)
    raise(ActiveRecord::RecordNotFound) unless Permissions.view_bills?(current_user, @bill.site)
    render layout: 'receipt'
  end
end
