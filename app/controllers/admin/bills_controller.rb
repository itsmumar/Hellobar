class Admin::BillsController < AdminController
  def show
    @bill = Bill.find(params[:id])
    @site = Site.with_deleted.find(@bill.site_id)
    @credit_card = @bill.successful_billing_attempt&.credit_card
    render 'bills/show', layout: 'receipt'
  end

  def void
    bill = Bill.find(params[:bill_id])
    bill.voided!
    flash[:success] = "Voided bill due on #{ bill.due_at.strftime('%D') } for #{ bill.amount }."
    redirect_to admin_user_path(params[:user_id])
  end

  def refund
    bill = Bill.find(params[:bill_id])
    begin
      amount = params[:bill_recurring][:amount].to_f
      RefundBill.new(bill, amount: amount).call
      flash[:success] = "Refund successful: Refunded #{ amount } of #{ bill.amount }."
    rescue RefundBill::InvalidRefund, RefundBill::MissingCreditCard, Bill::InvalidBillingAmount => e
      flash[:error] = "Refund error: #{ e.message }"
    end

    redirect_to admin_user_path(params[:user_id])
  end
end
