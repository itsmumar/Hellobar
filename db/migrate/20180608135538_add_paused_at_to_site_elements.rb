class AddPausedAtToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :paused_at, :datetime
  end
end
