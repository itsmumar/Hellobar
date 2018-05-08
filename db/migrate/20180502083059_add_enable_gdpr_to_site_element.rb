class AddEnableGdprToSiteElement < ActiveRecord::Migration
  def change
    add_column :site_elements, :enable_gdpr, :boolean, default: false
  end
end
