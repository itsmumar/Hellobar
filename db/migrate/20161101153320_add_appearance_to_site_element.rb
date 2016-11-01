class AddAppearanceToSiteElement < ActiveRecord::Migration
  def change
    add_column :site_elements, :appearance, :text
  end
end
