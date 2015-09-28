class AddDiscountToBill < ActiveRecord::Migration
  def change
    add_column :bills, :discount, :decimal, default: 0
    add_column :bills, :base_amount, :decimal
  end
end
