class RemoveConversionCtaTextfromSiteelement < ActiveRecord::Migration
  def change
    remove_column :site_elements, :conversion_cta_text, :text
  end
end
