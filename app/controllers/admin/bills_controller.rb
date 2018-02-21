class Admin::BillsController < AdminController
  def show
    @bill, @subscription, @site = load_data
    @credit_card = @bill.paid_with_credit_card
    render 'bills/show', layout: 'receipt'
  end

  def void
    @bill, @subscription, @site = load_data
    @bill.voided!
    flash[:success] = "Voided bill due on #{ @bill.due_at.strftime('%D') } for #{ @bill.amount }."

    redirect_to admin_site_path(@site)
  end

  def pay
    @bill, @subscription, @site = load_data
    PayBill.new(@bill).call

    if @bill.paid?
      flash[:success] = 'Bill is successfully paid'
    else
      flash[:error] = 'Could not pay the bill'
    end

    redirect_to admin_site_path(@site)
  rescue PayBill::MissingCreditCard => e
    flash[:error] = e.message
    redirect_to admin_site_path(@site)
  end

  def refund
    @bill, @subscription, @site = load_data
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
    bill = Bill.unscoped.find(params[:id])
    subscription = Subscription.unscoped { bill.subscription }
    site = Site.unscoped.find(params[:site_id])

    [bill, subscription, site]
  end
end
