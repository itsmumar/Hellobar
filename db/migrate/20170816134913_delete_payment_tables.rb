class DeletePaymentTables < ActiveRecord::Migration
  def change
    remove_column :credit_cards, :details_id, :integer
    remove_column :billing_attempts, :payment_method_details_id, :integer
    remove_column :subscriptions, :payment_method_id, :integer
    drop_table :payment_method_details do
    end
    drop_table :payment_methods do
    end
  end
end
