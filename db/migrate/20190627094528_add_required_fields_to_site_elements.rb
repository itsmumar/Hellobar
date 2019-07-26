class AddRequiredFieldsToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :required_fields, :boolean, default: false
  end
end
