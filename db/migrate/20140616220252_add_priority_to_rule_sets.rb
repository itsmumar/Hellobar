class AddPriorityToRuleSets < ActiveRecord::Migration
  def change
    add_column :rule_sets, :priority, :integer
  end
end
