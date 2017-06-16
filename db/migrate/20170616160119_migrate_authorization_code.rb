class MigrateAuthorizationCode < ActiveRecord::Migration
  def up
    Bill.paid.where('bill_at < ?', 2.months.ago).where.not(amount: 0).find_each do |bill|
      bill.update_column :authorization_code, bill.billing_attempts.success.last.response
    end
  end
end
