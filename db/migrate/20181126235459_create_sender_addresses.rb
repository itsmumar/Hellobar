class CreateSenderAddresses < ActiveRecord::Migration
  def change
    create_table :sender_addresses do |t|
      t.integer :site_id
      t.string :address_one
      t.string :address_two
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :country

      t.timestamps null: false
    end
    add_index :sender_addresses, :site_id
  end
end
