class CreatePartners < ActiveRecord::Migration
  def change
    create_table :partners do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :website_url
      t.string :affiliate_identifier, null: false
      t.string :partner_plan_id, null: false

      t.timestamps null: false
    end

    add_index :partners, [:affiliate_identifier], unique: true
  end
end
