class RenameGoalToBarType < ActiveRecord::Migration
  def change
    rename_column :bars, :goal, :bar_type
  end
end
