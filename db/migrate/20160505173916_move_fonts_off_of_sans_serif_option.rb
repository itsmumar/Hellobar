class MoveFontsOffOfSansSerifOption < ActiveRecord::Migration
  def up
    sans_serif = Font.find("sanserif")
    arial = Font.find("arial")

    SiteElement.where(font_id: sans_serif.id).update_all(font_id: arial.id)
  end

  def down
    sans_serif = Font.find("sanserif")
    arial = Font.find("arial")

    SiteElement.where(font_id: arial.id).update_all(font_id: sans_serif.id)
  end
end
