class ChangeConversionButtonTextTypeToSiteElement < ActiveRecord::Migration
  def change
    remove_column :site_elements, :conversion_cta_text, :string
    add_column :site_elements, :conversion_cta_text, :text
  end
end
