module Admin::UsersHelper
  def bills_for(site)
    bills = Hash.new { |h, k| h[k] = [] } # Bill => [Refunds]
    site.bills.select do |b|
      b.subscription.nil? ||
        !b.subscription.instance_of?(Subscription::Free)
    end.sort_by { |x| x.bill_at }.reverse.each do |bill|
      if bill.instance_of?(Bill::Refund)
        bills[bill.refunded_billing_attempt.bill] << bill
      else
        bills[bill]
      end
    end
    bills
  end

  def subscriptions
    ObjectSpace.each_object(Class).select { |klass| klass < Subscription }
  end

  def bill_duration(bill)
    "#{us_short_datetime(bill.start_date)}-#{us_short_datetime(bill.end_date)}"
  end

  private

  def us_short_datetime(datetime)
    datetime.to_date.to_s(:us_short)
  end
end
