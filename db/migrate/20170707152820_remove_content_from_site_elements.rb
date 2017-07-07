class RemoveContentFromSiteElements < ActiveRecord::Migration
  def change
    remove_column :site_elements, :content, :text
  end
end
