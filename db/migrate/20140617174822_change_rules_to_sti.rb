class ChangeRulesToSti < ActiveRecord::Migration
  def change
    remove_column :rule_sets, :end_date
    remove_column :rule_sets, :start_date
    remove_column :rule_sets, :include_urls
    remove_column :rule_sets, :exclude_urls

    add_column :rules, :type, :string, null: false
    add_column :rules, :operator, :string, null: false
    add_column :rules, :value, :text
  end
end
