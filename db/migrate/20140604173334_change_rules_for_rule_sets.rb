class ChangeRulesForRuleSets < ActiveRecord::Migration
  def change
    drop_table :rules

    create_table :rules do |t|
      t.belongs_to :rule_set
    end

    add_index :rules, :rule_set_id
  end
end
