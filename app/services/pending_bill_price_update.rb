class PendingBillPriceUpdate
  def initialize(bill)
    @bill = bill
  end

  def call
    find_subscription
  end

  private

  attr_reader :bill

  def find_subscription
    subscription = bill.subscription
    sort_subscription(subscription)
  end

  def sort_subscription(subscription)
    if subscription.name == 'Pro' || subscription.name == 'Growth'
      if subscription.schedule == 'yearly'
        modify_bill(289)
      else
        modify_bill(29)
      end
    elsif subscription.name == 'Elite'
      if subscription.schedule == 'yearly'
        modify_bill(999)
      else
        modify_bill(99)
      end
    end
  end

  def modify_bill(new_amount)
    bill.update(amount: new_amount)
  end
end
