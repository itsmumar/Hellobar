module Admin::UsersHelper
  def bills_for(site)
    site.bills.select { |b| b.amount != 0 }
  end
end
