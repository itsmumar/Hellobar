class AddDetailsIdToCreditCard < ActiveRecord::Migration
  def change
    add_column :credit_cards, :details_id, :integer
    add_index :credit_cards, :details_id
  end
end
