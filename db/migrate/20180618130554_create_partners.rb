class CreatePartners < ActiveRecord::Migration
  def change
    create_table :partners do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :website_url
      t.string :affiliate_identifier
      t.string :partner_plan_id

      t.timestamps null: false
    end
  end
end
