class AddContentToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :content, :text
  end
end
