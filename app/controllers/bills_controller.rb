class BillsController < ApplicationController
  before_action :authenticate_user!

  def show
    @bill = Bill.find(params[:id])
    @details = @bill.successful_billing_attempt.try(:payment_method_details)
    raise(ActiveRecord::RecordNotFound) unless @bill.site.owner == current_user
    render layout: 'receipt'
  end
end
