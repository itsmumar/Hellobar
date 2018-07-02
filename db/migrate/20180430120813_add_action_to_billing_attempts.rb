class AddActionToBillingAttempts < ActiveRecord::Migration
  def change
    add_column :billing_attempts, :action, :string, default: 'charge'
  end
end
