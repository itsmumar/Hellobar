class AddConversionButtonTextToSiteelement < ActiveRecord::Migration
  def change
    add_column :site_elements, :conversion_cta_text, :string, default: "Close"
  end
end
