class AddTitleAndURLToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :title, :string
    add_column :site_elements, :url, :text, limit: 500
  end
end
