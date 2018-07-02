class SwitchBillingAttemptsToStatusText < ActiveRecord::Migration
  def up
    remove_column :billing_attempts, :status
    rename_column :billing_attempts, :status_text, :status
  end

  def down
    rename_column :billing_attempts, :status, :status_text
    add_column :billing_attempts, :status, :integer
  end
end
