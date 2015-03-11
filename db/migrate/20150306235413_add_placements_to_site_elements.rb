class AddPlacementsToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :modal_placement, :string, default: "middle"
    add_column :site_elements, :slider_placement, :string, default: "bottom-right"
  end
end
