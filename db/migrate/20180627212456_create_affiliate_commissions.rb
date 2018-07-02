class CreateAffiliateCommissions < ActiveRecord::Migration
  def change
    create_table :affiliate_commissions do |t|
      t.integer :identifier, null: false
      t.integer :bill_id, null: false
    end

    add_index :affiliate_commissions, [:identifier, :bill_id]
  end
end
