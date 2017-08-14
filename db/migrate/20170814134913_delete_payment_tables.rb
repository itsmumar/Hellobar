class DeletePaymentTables < ActiveRecord::Migration
  def change
    remove_column :credit_cards, :details_id
    remove_column :billing_attempts, :payment_method_details_id
    remove_column :subscriptions, :payment_method_id
    drop_table :payment_method_details
    drop_table :payment_methods
  end
end
