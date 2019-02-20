class AddNoThankTextToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :no_thanks_text, :text
  end
end
