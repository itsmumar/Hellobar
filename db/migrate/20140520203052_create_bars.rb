class CreateBars < ActiveRecord::Migration
  def change
    create_table :bars do |t|
      t.belongs_to :rule

      t.timestamps
    end

    add_index :bars, :rule_id
  end
end
