class CreateAutofills < ActiveRecord::Migration
  def change
    create_table :autofills do |t|
      t.integer :site_id, null: false
      t.string :name, null: false
      t.string :listen_selector, null: false
      t.string :populate_selector, null: false

      t.timestamps
    end

    add_index :autofills, :site_id
  end
end
