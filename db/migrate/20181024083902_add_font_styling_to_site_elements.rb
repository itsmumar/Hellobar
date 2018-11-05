class AddFontStylingToSiteElements < ActiveRecord::Migration
  def up
    add_column :site_elements, :text_field_font_family, :string
    add_column :site_elements, :text_field_font_size, :integer, default: 14

    SiteElement.where(type: 'Takeover').update_all(text_field_font_size: 18)
  end

  def down
    remove_column :site_elements, :text_field_font_family
    remove_column :site_elements, :text_field_font_size
  end
end
