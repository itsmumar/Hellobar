class MigrateRefundedStatus < ActiveRecord::Migration
  def up
    Bill::Refund.update_all status: Bill::REFUNDED
  end

  def down
    Bill::Refund.update_all status: Bill::PAID
  end
end
