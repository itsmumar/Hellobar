class Admin::BillsController < ApplicationController
  layout "admin"

  before_action :require_admin

  def void
    bill = Bill.find(params[:bill_id])
    bill.void!
    flash[:success] = "Voided bill due on #{bill.due_at.strftime('%D')} for #{bill.amount}."
    redirect_to admin_user_path(params[:user_id])
  end

  def refund
    bill = Bill.find(params[:bill_id])
    begin
      amount = params[:full_amount] ? nil : params[:bill_recurring][:amount].to_f
      bill.refund!(nil, amount)
      flash[:success] = "Refund successful: Refunded #{amount} of #{bill.amount}."
    rescue BillingAttempt::InvalidRefund, Bill::InvalidBillingAmount => e
      flash[:error] = "Refund error: #{e.message}"
    end

    redirect_to admin_user_path(params[:user_id])
  end
end
