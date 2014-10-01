class RenameVisitOverageAddBackIndexes < ActiveRecord::Migration
  def change
    add_index :bills, ["subscription_id", "type", "bill_at"], name: "index_bills_on_subscription_id_and_type_and_bill_at", using: :btree
    add_index :bills, ["type", "bill_at"], name: "index_bills_on_type_and_bill_at", using: :btree

    rename_column :subscriptions, :_visit_overage, :visit_overage
    rename_column :subscriptions, :_visit_overage_unit, :visit_overage_unit
    rename_column :subscriptions, :_visit_overage_amount, :visit_overage_amount
  end
end
