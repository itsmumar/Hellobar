class AddTargetNewWindowToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :open_in_new_window, :bool, default: false
  end
end
