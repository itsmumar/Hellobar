class AddThankYouTextToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :thank_you_text, :string
  end
end
