class CreateRules < ActiveRecord::Migration
  def change
    create_table :rules do |t|
      t.belongs_to :site

      t.timestamps
    end

    add_index :rules, :site_id
  end
end
