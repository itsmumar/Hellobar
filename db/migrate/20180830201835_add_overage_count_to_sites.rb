class AddOverageCountToSites < ActiveRecord::Migration
  def change
    add_column :sites, :overage_count, :integer, default: 0
  end
end
