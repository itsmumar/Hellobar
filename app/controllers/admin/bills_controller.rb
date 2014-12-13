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
    if params[:full_amount]
      bill.refund!
      flash[:success] = "Refunded entire bill amount of #{bill.amount}."
    elsif params[:bill_recurring].try(:[], :amount)
      amount = params[:bill_recurring][:amount].to_f
      bill.refund!(nil, amount)
      flash[:success] = "Refunded #{amount} of #{bill.amount}."
    else
      flash[:error] = "Error refunding"
    end

    redirect_to admin_user_path(params[:user_id])
  end
end
