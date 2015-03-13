class AddPlacementToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :placement, :string
    remove_column :site_elements, :modal_placement, :string
    remove_column :site_elements, :slider_placement, :string
  end
end
