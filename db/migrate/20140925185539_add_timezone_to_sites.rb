class AddTimezoneToSites < ActiveRecord::Migration
  def change
    add_column :sites, :timezone, :string
  end
end
