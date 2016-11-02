class AddBlocksToSiteElement < ActiveRecord::Migration
  def up
    add_column :site_elements, :blocks, :text
  end

  def down
    remove_column :site_elements, :blocks, :text
  end
end
