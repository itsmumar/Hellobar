class AddDeletedAtToContactList < ActiveRecord::Migration
  def change
    add_column :contact_lists, :deleted_at, :datetime
  end
end
