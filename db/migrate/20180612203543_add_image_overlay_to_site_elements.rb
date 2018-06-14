class AddImageOverlayToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :image_overlay_color, :string, limit: 10, default: 'ffffff'
    add_column :site_elements, :image_overlay_opacity, :integer, limit: 1, default: 0 # tinyint
  end
end
