class AddScriptInstalledAtToSites < ActiveRecord::Migration
  def change
    add_column :sites, :script_installed_at, :datetime
  end
end
