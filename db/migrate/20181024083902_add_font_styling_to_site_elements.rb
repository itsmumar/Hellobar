class AddFontStylingToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :text_field_font_family, :string, limit: 255
    add_column :site_elements, :text_field_font_size, :integer, limit: 4, default: 14

    SiteElement.where(type: 'Takeover').update_all(text_field_font_size: 18)
  end
end
