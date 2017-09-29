class RemoveCustomSegmentFromConditions < ActiveRecord::Migration
  def up
    Condition.where(segment: 'CustomCondition').destroy_all

    remove_column :conditions, :custom_segment
  end

  def down
    add_column :conditions, :custom_segment, :string, limit: 255
  end
end
