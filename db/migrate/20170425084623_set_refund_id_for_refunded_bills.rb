class SetRefundIdForRefundedBills < ActiveRecord::Migration
  def up
    Bill::Refund.find_each do |refund|
      refund.update(refunded_bill: refund.refunded_billing_attempt.bill) if refund.refunded_billing_attempt
    end
  end

  def down
  end
end
