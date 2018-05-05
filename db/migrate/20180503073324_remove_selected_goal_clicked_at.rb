class RemoveSelectedGoalClickedAt < ActiveRecord::Migration
  def change
    remove_column :sites, :selected_goal_clicked_at, :datetime
  end
end
