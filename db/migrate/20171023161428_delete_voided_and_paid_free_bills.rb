class DeleteVoidedAndPaidFreeBills < ActiveRecord::Migration
  def change
    puts "Found #{ scope.count } free bills"
    puts "    #{ paid.count } STATE_PAID bills to delete"
    puts "    Found #{ voided.count } STATE_VOIDED bills to delete"
    voided.delete_all
    paid.delete_all
  end

  def scope
    Bill.joins(:subscription)
      .where(subscriptions: {
        type: ['Subscription::Free']
      })
  end

  def paid
    scope.where(status: Bill::STATE_PAID, type: 'Bill::Recurring')
  end

  def voided
    scope.where(status: Bill::STATE_VOIDED, type: 'Bill::Recurring')
  end
end
