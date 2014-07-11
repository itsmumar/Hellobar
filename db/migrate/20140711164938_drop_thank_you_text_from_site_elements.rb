class DropThankYouTextFromSiteElements < ActiveRecord::Migration
  def change
    remove_column :site_elements, :thank_you_text
  end
end
