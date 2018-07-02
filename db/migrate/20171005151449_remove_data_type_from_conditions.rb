class RemoveDataTypeFromConditions < ActiveRecord::Migration
  def change
    remove_column :conditions, :data_type, :string, limit: 255
  end
end
