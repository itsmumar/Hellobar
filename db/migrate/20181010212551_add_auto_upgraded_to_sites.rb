class AddAutoUpgradedToSites < ActiveRecord::Migration
  def change
    add_column :sites, :auto_upgraded_at, :datetime
  end
end
