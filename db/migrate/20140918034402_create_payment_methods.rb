class CreatePaymentMethods < ActiveRecord::Migration
  def change
    create_table :payment_methods do |t|
      t.belongs_to :user
      t.integer :status, :default => 0
      t.timestamps
    end
  end
end
