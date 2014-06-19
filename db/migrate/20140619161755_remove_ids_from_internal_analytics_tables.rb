class RemoveIdsFromInternalAnalyticsTables < ActiveRecord::Migration
  def change
    remove_column :internal_dimensions, :id
    remove_column :internal_processing, :id
  end
end
