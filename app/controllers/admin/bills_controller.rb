class Admin::BillsController < AdminController
  def show
    load_data
    @credit_card = @bill.paid_with_credit_card
    render 'bills/show', layout: 'receipt'
  end

  def void
    load_data
    @bill.voided!
    flash[:success] = "Voided bill due on #{ @bill.due_at.strftime('%D') } for #{ @bill.amount }."

    redirect_to admin_site_path(@site)
  end

  def pay
    load_data
    PayBill.new(@bill).call
    flash[:success] = 'Bill is successfully paid'

    redirect_to admin_site_path(@site)
  end

  def refund
    load_data
    begin
      amount = params[:bill_recurring][:amount].to_f
      RefundBill.new(@bill, amount: amount).call
      flash[:success] = "Refund successful: Refunded #{ amount } of #{ @bill.amount }."
    rescue RefundBill::InvalidRefund, RefundBill::MissingCreditCard, Bill::InvalidBillingAmount => e
      flash[:error] = "Refund error: #{ e.message }"
    end

    redirect_to admin_site_path(@site)
  end

  private

  def load_data
    @bill = Bill.find(params[:id])
    @subscription = @bill.subscription
    @site = Site.find(params[:site_id])
  end
end
