class AddNameToRuleSets < ActiveRecord::Migration
  def change
    add_column :rule_sets, :name, :string
  end
end
