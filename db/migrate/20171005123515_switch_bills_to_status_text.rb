class SwitchBillsToStatusText < ActiveRecord::Migration
  def up
    remove_index :bills, [:status, :bill_at]
    remove_index :bills, [:subscription_id, :status, :bill_at]

    remove_column :bills, :status
    rename_column :bills, :status_text, :status

    add_index :bills, [:status, :bill_at]
    add_index :bills, [:subscription_id, :status, :bill_at]
  end

  def down
    remove_index :bills, [:status, :bill_at]
    remove_index :bills, [:subscription_id, :status, :bill_at]

    rename_column :bills, :status, :status_text
    add_column :bills, :status, :integer

    add_index :bills, [:status, :bill_at]
    add_index :bills, [:subscription_id, :status, :bill_at]
  end
end
