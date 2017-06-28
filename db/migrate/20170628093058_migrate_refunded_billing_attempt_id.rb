class MigrateRefundedBillingAttemptId < ActiveRecord::Migration
  def up
    Bill.where("metadata like '{%}'").find_each.with_index do |bill, i|
      bill.update_column :refunded_billing_attempt_id, bill.metadata['refunded_billing_attempt_id']
      puts "Updated #{ i } records" if i % 100 == 0
    end
  end
end
