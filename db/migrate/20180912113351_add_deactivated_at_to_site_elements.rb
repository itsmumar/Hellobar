class AddDeactivatedAtToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :deactivated_at, :datetime
  end
end
