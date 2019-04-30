class AddEditConversionButtonTextToSiteElement < ActiveRecord::Migration
  def change
    add_column :site_elements, :edit_conversion_cta_text, :boolean, default: false
  end
end
