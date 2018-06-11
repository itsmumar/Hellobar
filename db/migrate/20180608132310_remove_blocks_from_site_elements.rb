class RemoveBlocksFromSiteElements < ActiveRecord::Migration
  def change
    remove_column :site_elements, :blocks, :text
  end
end
