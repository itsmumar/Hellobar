class RemovePriorityFromRules < ActiveRecord::Migration
  def change
    remove_column :rules, :priority, :integer, limit: 4
  end
end
