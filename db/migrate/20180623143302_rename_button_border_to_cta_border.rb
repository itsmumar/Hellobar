class RenameButtonBorderToCtaBorder < ActiveRecord::Migration
  def change
    rename_column :site_elements, :button_border, :cta_border
    rename_column :site_elements, :button_border_color, :cta_border_color
    rename_column :site_elements, :button_border_radius, :cta_border_radius
    rename_column :site_elements, :button_border_width, :cta_border_width
  end
end
