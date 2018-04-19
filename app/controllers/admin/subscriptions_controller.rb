class Admin::SubscriptionsController < AdminController
  def index
    @subscriptions = paginate(scope)
  end

  def filter_by_type
    @subscriptions = paginate(scope.where(type: "Subscription::#{ params[:type].classify }"))
    render :index
  end

  def ended_trial
    @subscriptions = paginate(scope.ended_trial)
    render :index
  end

  def show
    @subscription = Subscription.find(params[:id])
  end

  private

  def scope
    Subscription.includes(:last_paid_bill, :credit_card, site: :users).order(id: :desc)
  end

  def paginate(relation)
    relation.page(params[:page])
  end
end
