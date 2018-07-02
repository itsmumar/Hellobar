class MigrateRefundedStatus < ActiveRecord::Migration
  def up
    Bill::Refund.update_all status: Bill::STATE_REFUNDED
  end

  def down
    Bill::Refund.update_all status: Bill::STATE_PAID
  end
end
