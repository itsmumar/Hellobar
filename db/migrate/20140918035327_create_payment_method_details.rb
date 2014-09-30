class CreatePaymentMethodDetails < ActiveRecord::Migration
  def change
    create_table :payment_method_details do |t|
      t.belongs_to :payment_method
      t.string :type
      t.text :data # JSON hash of cybersource_token, card_number, address, etc
      t.datetime :created_at
    end
  end
end
