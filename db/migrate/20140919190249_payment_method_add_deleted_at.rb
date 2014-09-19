class PaymentMethodAddDeletedAt < ActiveRecord::Migration
  def change
    remove_column :payment_methods, :status
    add_column :payment_methods, :deleted_at, :datetime
    add_index :payment_methods, :deleted_at
  end
end
