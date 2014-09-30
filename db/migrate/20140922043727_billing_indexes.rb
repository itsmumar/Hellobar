class BillingIndexes < ActiveRecord::Migration
  def change
    add_index :payment_methods, :user_id
    add_index :payment_method_details, :payment_method_id
    add_index :bills, [:subscription_id, :status, :bill_at]
    add_index :bills, [:status, :bill_at]
    add_index :billing_logs, :created_at
    add_index :billing_logs, :user_id
    add_index :billing_logs, :site_id
    add_index :billing_logs, :payment_method_id
    add_index :billing_logs, :payment_method_details_id
    add_index :billing_logs, :bill_id
    add_index :billing_logs, :billing_attempt_id
    add_index :billing_logs, :subscription_id
    add_index :billing_attempts, :bill_id
    add_index :billing_attempts, :payment_method_details_id
    add_index :subscriptions, :site_id
    add_index :subscriptions, :created_at
    add_index :subscriptions, :payment_method_id
  end
end
