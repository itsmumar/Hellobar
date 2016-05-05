class RenameFontToFontId < ActiveRecord::Migration
  def up
    rename_column :site_elements, :font, :font_id
    change_column_default :site_elements, :font_id, "open_sans"

    Font.all.each do |font|
      SiteElement.where(font_id: font.value).update_all(font_id: font.id)
    end
  end

  def down
    Font.all.each do |font|
      SiteElement.where(font_id: font.id).update_all(font_id: font.value)
    end

    rename_column :site_elements, :font_id, :font
    change_column_default :site_elements, :font, "'Open Sans',sans-serif"
  end
end
