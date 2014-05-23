class AddGoalToBars < ActiveRecord::Migration
  def change
    add_column :bars, :goal, :string, :null => false
    add_index :bars, :goal
  end
end
