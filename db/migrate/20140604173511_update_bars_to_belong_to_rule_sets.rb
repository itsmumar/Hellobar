class UpdateBarsToBelongToRuleSets < ActiveRecord::Migration
  def change
    remove_column :bars, :rule_id
    add_column :bars, :rule_set_id, :integer
    add_index :bars, :rule_set_id
  end
end
