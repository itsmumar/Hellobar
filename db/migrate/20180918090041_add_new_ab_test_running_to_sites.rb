class AddNewAbTestRunningToSites < ActiveRecord::Migration
  def change
    add_column :sites, :ab_test_running, :boolean, default: false
  end
end
