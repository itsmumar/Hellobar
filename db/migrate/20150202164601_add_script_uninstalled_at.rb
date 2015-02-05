class AddScriptUninstalledAt < ActiveRecord::Migration
  def change
    add_column :sites, :script_uninstalled_at, :datetime
  end
end
