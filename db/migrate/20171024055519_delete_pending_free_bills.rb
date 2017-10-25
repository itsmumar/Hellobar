class DeletePendingFreeBills < ActiveRecord::Migration
  def up
    puts "Found #{ scope.count } free bills"
    puts "    #{ pending.count } PENDING bills to delete"
    pending.delete_all
  end

  def scope
    Bill.joins(:subscription)
      .where(subscriptions: {
        type: ['Subscription::Free']
      })
  end

  def pending
    scope.where(status: Bill::PENDING, type: 'Bill::Recurring')
  end
end
