class CreateRuleSettings < ActiveRecord::Migration
  def change
    create_table :rule_settings do |t|
      t.datetime :end_date
      t.datetime :start_date

      t.text :exclude_urls
      t.text :include_urls

      t.belongs_to :rule

      t.timestamps
    end

    add_index :rule_settings, :rule_id, :unique => true
  end
end
