class AddTapfilateCommissionIdToBills < ActiveRecord::Migration
  def change
    add_column :bills, :tapfiliate_commission_id, :integer, null: true
  end
end
