class AddPausedAtToSiteElements < ActiveRecord::Migration
  def up
    add_column :site_elements, :paused_at, :datetime
  end
end
