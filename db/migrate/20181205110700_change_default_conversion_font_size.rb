class ChangeDefaultConversionFontSize < ActiveRecord::Migration
  def change
    change_column_default :site_elements, :conversion_font_size, 22
  end
end
