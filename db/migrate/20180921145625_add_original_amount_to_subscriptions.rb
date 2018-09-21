class AddOriginalAmountToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :original_amount, :decimal, scale: 2, precision: 7
  end
end
