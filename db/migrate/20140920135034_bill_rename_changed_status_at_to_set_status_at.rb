class BillRenameChangedStatusAtToSetStatusAt < ActiveRecord::Migration
  def change
    rename_column :bills, :changed_status_at, :status_set_at
  end
end
