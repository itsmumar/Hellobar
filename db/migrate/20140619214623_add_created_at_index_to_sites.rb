class AddCreatedAtIndexToSites < ActiveRecord::Migration
  def change
    add_index :sites, :created_at
  end
end
