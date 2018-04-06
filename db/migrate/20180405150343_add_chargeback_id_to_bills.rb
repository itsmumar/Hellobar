class AddChargebackIdToBills < ActiveRecord::Migration
  def change
    add_column :bills, :chargeback_id, :integer
  end
end
