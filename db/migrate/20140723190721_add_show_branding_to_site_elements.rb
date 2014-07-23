class AddShowBrandingToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :show_branding, :boolean, :default => true
  end
end
