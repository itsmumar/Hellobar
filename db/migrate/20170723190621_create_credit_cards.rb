class CreateCreditCards < ActiveRecord::Migration
  def change
    create_table :credit_cards do |t|
      t.string :number, null: false
      t.integer :month, null: false
      t.integer :year, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :brand, null: false
      t.string :city, null: false
      t.string :state, null: false
      t.string :zip, null: false
      t.string :address, null: false
      t.string :country, null: false
      t.string :token, null: false
      t.belongs_to :user, index: true, foreign_key: true

      t.datetime :deleted_at
      t.timestamps null: false
    end
    change_table :subscriptions do |t|
      t.belongs_to :credit_card, index: true, foreign_key: true
    end
    change_table :billing_attempts do |t|
      t.belongs_to :credit_card, index: true, foreign_key: true
    end
  end
end
