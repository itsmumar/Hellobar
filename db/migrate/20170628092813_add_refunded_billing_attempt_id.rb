class AddRefundedBillingAttemptId < ActiveRecord::Migration
  def change
    add_column :bills, :refunded_billing_attempt_id, :integer
    add_index :bills, :refunded_billing_attempt_id
  end
end
