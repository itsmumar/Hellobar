class AddConversionColumns < ActiveRecord::Migration
  def change
    add_column :site_elements, :conversion_font, :string, default: 'Roboto', null: false
    add_column :site_elements, :conversion_font_color, :string, default: 'ffffff', null: false
    add_column :site_elements, :conversion_font_size, :integer, default: 12, null: false
  end
end
