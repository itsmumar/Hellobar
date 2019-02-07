class RemoveThanksStylingfromSiteElements < ActiveRecord::Migration
  def change
    remove_column :site_elements, :no_thanks_font_size, :integer
    remove_column :site_elements, :no_thanks_font_color, :string
    remove_column :site_elements, :no_thanks_font_family, :string
    remove_column :site_elements, :no_thanks_text, :string
  end
end
