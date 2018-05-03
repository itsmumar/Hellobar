class Admin::BillsController < AdminController
  def index
    @bills = Bill.order(id: :desc).page(params[:page])
  end

  def filter_by_status
    @bills = Bill.order(id: :desc).where(status: params[:status]).page(params[:page])
    render :index
  end

  def show
    @bill, @subscription, @site = load_data
    @credit_card = @bill.paid_with_credit_card
  end

  def receipt
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
      RefundBill.new(@bill).call
      flash[:success] = "Refund successful: Refunded #{ @bill.amount }."
    rescue RefundBill::InvalidRefund, RefundBill::MissingCreditCard, Bill::InvalidBillingAmount => e
      flash[:error] = "Refund error: #{ e.message }"
    end

    redirect_to admin_site_path(@site)
  end

  def chargeback
    @bill, @subscription, @site = load_data
    ChargebackBill.new(@bill).call
    flash[:success] = 'Chargeback successful.'

    redirect_to admin_site_path(@site)
  end

  private

  def load_data
    bill = Bill.unscoped.find(params[:id])
    subscription = Subscription.unscoped { bill.subscription }
    site = Site.unscoped.find(bill.site_id)

    [bill, subscription, site]
  end
end
