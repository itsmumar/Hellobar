class AddConversionCtaToSiteElement < ActiveRecord::Migration
  def change
    add_column :site_elements, :conversion_cta_text, :text
  end
end
