class AddStripeAttributesToTables < ActiveRecord::Migration
  def change
    add_column :credit_cards, :stripe_id, :string
    add_column :subscriptions, :stripe_subscription_id, :string
    add_column :users, :stripe_customer_id, :string

    change_column :credit_cards, :number, :string, :null => true
    change_column :credit_cards, :first_name, :string, :null => true
    change_column :credit_cards, :last_name, :string, :null => true
    change_column :credit_cards, :city, :string, :null => true
    change_column :credit_cards, :state, :string, :null => true
    change_column :credit_cards, :zip, :string, :null => true
    change_column :credit_cards, :address, :string, :null => true
    change_column :credit_cards, :token, :string, :null => true
  end
end
