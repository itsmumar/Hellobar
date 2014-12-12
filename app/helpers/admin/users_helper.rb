module Admin::UsersHelper
  def bills_for(site)
    site.bills.select { |b| b.amount != 0 }.sort_by { |x| x.bill_at }.reverse
  end
end
