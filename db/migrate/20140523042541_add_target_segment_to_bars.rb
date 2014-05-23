class AddTargetSegmentToBars < ActiveRecord::Migration
  def change
    add_column :bars, :target_segment, :string
  end
end
