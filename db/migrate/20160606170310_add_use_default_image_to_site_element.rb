class AddUseDefaultImageToSiteElement < ActiveRecord::Migration
  def change
    add_column :site_elements, :use_default_image, :boolean, null: false, default: true
  end
end
