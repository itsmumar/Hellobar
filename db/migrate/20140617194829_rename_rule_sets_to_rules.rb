class RenameRuleSetsToRules < ActiveRecord::Migration
  def change
    rename_table :rule_sets, :rules

    rename_column :conditions, :rule_set_id, :rule_id
    rename_column :bars, :rule_set_id, :rule_id
  end
end
