class SetDefaultConversionFontSize < ActiveRecord::Migration
  def change
    change_column_default :site_elements, :conversion_font_size, 16
  end
end
