class AddImageOpacityToSiteElement < ActiveRecord::Migration
  def change
    add_column :site_elements, :image_opacity, :integer, default: 100
  end
end
