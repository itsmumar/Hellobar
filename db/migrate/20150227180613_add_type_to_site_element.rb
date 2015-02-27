class AddTypeToSiteElement < ActiveRecord::Migration
  def change
    add_column :site_elements, :type, :string, default: "Bar"
    add_column :site_elements, :caption, :string
    rename_column :site_elements, :message, :headline
  end
end
