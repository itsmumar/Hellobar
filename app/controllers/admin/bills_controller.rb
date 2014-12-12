class Admin::BillsController < ApplicationController
  layout "admin"

  before_action :require_admin

  def void
    bill = Bill.find(params[:bill_id])
    bill.void!
    flash[:success] = "Voided bill due on #{bill.due_at.strftime('%D')} for #{bill.amount}."
    redirect_to admin_user_path(params[:user_id])
  end
end
