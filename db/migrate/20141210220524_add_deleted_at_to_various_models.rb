class AddDeletedAtToVariousModels < ActiveRecord::Migration
  def change
    add_column :users, :deleted_at, :datetime
    add_column :site_memberships, :deleted_at, :datetime
    add_column :sites, :deleted_at, :datetime
  end
end
