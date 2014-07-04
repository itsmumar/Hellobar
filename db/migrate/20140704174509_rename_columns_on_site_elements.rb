class RenameColumnsOnSiteElements < ActiveRecord::Migration
  def change
    rename_column :site_elements, :bar_color, :background_color
    rename_column :site_elements, :bar_type, :element_subtype
  end
end
