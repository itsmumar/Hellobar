class SwitchBillingAttemptsToStatusText < ActiveRecord::Migration
  def change
    remove_column :billing_attempts, :status
    rename_column :billing_attempts, :status_text, :status
  end
end
