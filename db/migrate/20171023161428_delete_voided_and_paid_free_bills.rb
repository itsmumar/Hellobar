class DeleteVoidedAndPaidFreeBills < ActiveRecord::Migration
  def change
    puts "Found #{ scope.count } free bills"
    puts "    #{ paid.count } PAID bills to delete"
    puts "    Found #{ voided.count } VOIDED bills to delete"
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
    scope.where(status: Bill::PAID, type: 'Bill::Recurring')
  end

  def voided
    scope.where(status: Bill::VOIDED, type: 'Bill::Recurring')
  end
end
