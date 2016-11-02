class AddContentAndAppearanceToSiteElement < ActiveRecord::Migration
  def up
    add_column :site_elements, :content, :text
    add_column :site_elements, :appearance, :text
  end
  def down
    remove_column :site_elements, :content, :text
    remove_column :site_elements, :appearance, :text
  end
end
