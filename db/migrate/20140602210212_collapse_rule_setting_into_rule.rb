class CollapseRuleSettingIntoRule < ActiveRecord::Migration
  def change
    drop_table :rule_settings

    add_column :rules, :end_date, :datetime
    add_column :rules, :start_date, :datetime

    add_column :rules, :exclude_urls, :text
    add_column :rules, :include_urls, :text
  end
end
