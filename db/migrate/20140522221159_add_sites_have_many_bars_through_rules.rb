class AddSitesHaveManyBarsThroughRules < ActiveRecord::Migration
  def change
    add_column :rules, :site_id, :integer, null: false
    add_column :rules, :bar_id, :integer, null: false
    add_index :rules, [:site_id, :bar_id], unique: true
  end
end
