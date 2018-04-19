class RemoveRefundedBillingAttempt < ActiveRecord::Migration
  def change
    remove_column :bills, :refunded_billing_attempt_id, :integer
  end
end
