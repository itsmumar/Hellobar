class CreateRuleSets < ActiveRecord::Migration
  def change
    create_table :rule_sets do |t|
      t.datetime :end_date
      t.datetime :start_date

      t.text :include_urls
      t.text :exclude_urls

      t.belongs_to :site

      t.timestamps
    end

    add_index :rule_sets, :site_id
  end
end
