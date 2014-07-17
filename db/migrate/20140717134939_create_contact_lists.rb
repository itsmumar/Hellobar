class CreateContactLists < ActiveRecord::Migration
  def change
    create_table :contact_lists do |t|
      t.integer :site_id, :identity_id
      t.string :name
      t.text :data
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :contact_lists, :site_id
    add_index :contact_lists, :identity_id
  end
end
