class CreateAffiliateInformation < ActiveRecord::Migration
  def change
    create_table :affiliate_information do |t|
      t.references :user, index: true, null: false
      t.string :visitor_identifier, null: false
      t.string :affiliate_identifier, null: false

      t.timestamps null: false
    end

    add_foreign_key :affiliate_information, :users, column: :user_id
  end
end
