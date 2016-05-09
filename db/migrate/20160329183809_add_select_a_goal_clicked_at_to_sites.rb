class AddSelectAGoalClickedAtToSites < ActiveRecord::Migration
  def change
    add_column :sites, :selected_goal_clicked_at, :datetime
  end
end
