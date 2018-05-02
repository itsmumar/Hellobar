class RemoveRefundIdAndChargebackIdColumns < ActiveRecord::Migration
  def change
    remove_reference :bills, :refund, index: true
    remove_reference :bills, :chargeback, index: false
  end
end
