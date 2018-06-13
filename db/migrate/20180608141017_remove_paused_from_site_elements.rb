class RemovePausedFromSiteElements < ActiveRecord::Migration
  def change
    remove_column :site_elements, :paused, :boolean, default: false
  end
end
