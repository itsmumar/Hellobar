class DropLastSyncedAtFromContactLists < ActiveRecord::Migration
  def change
    remove_column :contact_lists, :last_synced_at, :datetime
  end
end
