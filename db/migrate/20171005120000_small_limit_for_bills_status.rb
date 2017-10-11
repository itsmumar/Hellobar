class SmallLimitForBillsStatus < ActiveRecord::Migration
  def up
    change_column :bills, :status, :string, limit: 20, default: "pending", null: false
  end

  def down
    change_column :bills, :status, :string, limit: 255, default: "pending", null: false
  end
end
