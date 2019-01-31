class AddNoThanksStylingToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :no_thanks_font_size, :integer, default: 14
    add_column :site_elements, :no_thanks_font_color, :string
    add_column :site_elements, :no_thanks_font_family, :string
  end
end
