class AddPausedToBars < ActiveRecord::Migration
  def change
    add_column :bars, :paused, :boolean, default: false
  end
end
