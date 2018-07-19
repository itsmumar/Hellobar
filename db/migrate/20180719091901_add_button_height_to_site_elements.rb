class AddButtonHeightToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :cta_height, :integer, default: 27, null: false
  end
end
