class Bill
  class Recurring < self
    def self.next_month(date)
      date + 1.month
    end

    def self.next_year(date)
      date + 1.year
    end

    def renewal_date
      raise 'can not calculate renewal date without start_date' unless start_date
      subscription.monthly? ? self.class.next_month(start_date) : self.class.next_year(start_date)
    end

    def on_paid
      super
      # Create the next bill
      next_method = subscription.monthly? ? :next_month : :next_year
      new_start_date = end_date
      new_bill = Bill::Recurring.new(
        subscription: subscription,
        amount: subscription.amount,
        description: "#{ subscription.monthly? ? 'Monthly' : 'Yearly' } Renewal",
        grace_period_allowed: true,
        bill_at: end_date,
        start_date: new_start_date,
        end_date: Bill::Recurring.send(next_method, new_start_date)
      )
      audit << "Paid recurring bill, created new bill for #{ subscription.amount } that starts at #{ new_start_date }. #{ new_bill.inspect }"
      new_bill.save!
      new_bill
    end
  end
end
