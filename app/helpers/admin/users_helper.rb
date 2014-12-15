module Admin::UsersHelper
  def bills_for(site)
    bills = Hash.new { |h, k| h[k] = [] } # Bill => [Refunds]
    site.bills.select { |b| b.amount != 0 }.sort_by { |x| x.bill_at }.reverse.each do |bill|
      if bill.instance_of?(Bill::Refund)
        bills[bill.refunded_billing_attempt.bill] << bill
      else
        bills[bill]
      end
    end
    bills
  end
end
