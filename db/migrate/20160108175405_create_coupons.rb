class CreateCoupons < ActiveRecord::Migration
  def change
    create_table :coupons do |t|
      t.string :label
      t.integer :available_uses
      t.decimal :amount, precision: 7, scale: 2

      t.timestamps
    end
  end
end
