class AddCustomSegmentToCondition < ActiveRecord::Migration
  def change
    add_column :conditions, :custom_segment, :string
    add_column :conditions, :data_type, :string
  end
end
