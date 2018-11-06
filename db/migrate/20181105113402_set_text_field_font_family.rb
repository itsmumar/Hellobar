class SetTextFieldFontFamily < ActiveRecord::Migration
  def up
    SiteElement.update_all("text_field_font_family = font_id")
  end
end
