class MigrateAuthorizationCode < ActiveRecord::Migration
  def up
    Bill.paid.where('amount > 0').find_each do |bill|
      next unless attempt = bill.billing_attempts.success.last
      bill.update_column :authorization_code, attempt.response
    end
  end
end
