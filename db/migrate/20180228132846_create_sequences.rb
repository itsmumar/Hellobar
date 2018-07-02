class CreateSequences < ActiveRecord::Migration
  def change
    create_table :sequences do |t|
      t.string :name, null: false

      t.references :contact_list, index: true, null: false

      t.datetime :deleted_at

      t.timestamps
    end
  end
end
