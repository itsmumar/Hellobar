class AddContentToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :content, :text, after: :caption
  end
end
