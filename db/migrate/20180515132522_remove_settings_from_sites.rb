class RemoveSettingsFromSites < ActiveRecord::Migration
  def change
    remove_column :sites, :settings, :text
  end
end
