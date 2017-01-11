class AddSettingsToSites < ActiveRecord::Migration
  def change
    add_column :sites, :settings, :text
  end
end
