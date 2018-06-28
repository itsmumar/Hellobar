class AddButtonBorderToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :button_border, :boolean, default: false, null: false
    add_column :site_elements, :button_border_color, :string, default: 'ffffff', null: false
    add_column :site_elements, :button_border_width, :integer, default: 0, null: false
    add_column :site_elements, :button_border_radius, :integer, default: 0, null: false
  end
end
