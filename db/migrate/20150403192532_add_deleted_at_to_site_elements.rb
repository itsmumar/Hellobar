class AddDeletedAtToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :deleted_at, :datetime
    add_column :rules, :deleted_at, :datetime
  end
end
