class AddRefundIdToBills < ActiveRecord::Migration
  def change
    add_reference :bills, :refund, index: true
  end
end
