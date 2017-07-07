class MigrateBillEndDate < ActiveRecord::Migration
  def up
    bills = Bill.joins(:subscription)
              .pending.where.not(subscriptions: { type: 'Subscription::Free' })
              .where('bill_at >= ?', Time.current)

    bills.find_each.with_index do |bill, i|
      bill.update bill_at: 3.day.until(bill.start_date)
      puts "Updated #{ i } records" if i % 100 == 0
    end
  end
end
