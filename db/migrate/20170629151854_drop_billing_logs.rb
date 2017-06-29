class DropBillingLogs < ActiveRecord::Migration
  def change
    drop_table :billing_logs
  end
end
