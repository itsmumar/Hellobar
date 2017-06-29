class RemoveMetadataFromBills < ActiveRecord::Migration
  def up
    remove_column :bills, :metadata
  end
end
