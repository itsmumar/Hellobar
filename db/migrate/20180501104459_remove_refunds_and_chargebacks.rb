class RemoveRefundsAndChargebacks < ActiveRecord::Migration
  class BillStub < ActiveRecord::Base
    self.table_name = :bills
    self.inheritance_column = :_type
  end

  class BillingAttemptStub < ActiveRecord::Base
    self.table_name = :billing_attempts
  end

  def up
    BillStub.where(type: 'Bill::Refund').find_in_batches do |refunds|
      bills = BillStub.where(refund_id: refunds.map(&:id)).index_by(&:refund_id)

      refunds.each do |refund|
        bill = bills[refund.id]
        next unless bill

        BillStub.transaction do
          BillingAttemptStub.create!(
            bill_id: bill.id,
            response: refund.authorization_code,
            status: refund.status == 'refunded' ? 'successful' : 'failed',
            action: 'refund',
            created_at: refund.created_at
          )

          bill.update!(status: 'refunded', status_set_at: refund.created_at)
          refund.destroy
        end
      end
    end

    BillStub.where(type: 'Bill::Chargeback').find_in_batches do |chargebacks|
      bills = BillStub.where(chargeback_id: chargebacks.map(&:id)).index_by(&:chargeback_id)

      chargebacks.each do |chargeback|
        bill = bills[chargeback.id]
        next unless bill

        BillStub.transaction do
          BillingAttemptStub.create!(
            bill_id: bill.id,
            status: 'successful',
            action: 'chargeback',
            created_at: chargeback.created_at
          )

          bill.update!(status: 'chargedback', status_set_at: chargeback.created_at)
          chargeback.destroy
        end
      end
    end
  end

  def down
    BillStub.where(status: 'refunded').find_in_batches do |bills|
      billing_attempts = BillingAttemptStub.where(action: 'refund', bill_id: bills.map(&:id)).index_by(&:bill_id)

      bills.each do |bill|
        attempt = billing_attempts[bill.id]
        next unless attempt

        refund = BillStub.create!(
          type: 'Bill::Refund',
          subscription_id: bill.subscription_id,
          amount: bill.amount,
          description: 'Refund due to customer service request',
          created_at: attempt.created_at,
          bill_at: attempt.created_at,
          start_date: attempt.created_at,
          end_date: bill.end_date,
          status: attempt.status == 'successful' ? 'refunded' : 'voided',
          authorization_code: attempt.response
        )

        bill.update!(status: 'paid', refund_id: refund.id)
        attempt.destroy
      end
    end

    BillStub.where(status: 'chargedback').find_in_batches do |bills|
      billing_attempts = BillingAttemptStub.where(action: 'chargeback', bill_id: bills.map(&:id)).index_by(&:bill_id)

      bills.each do |bill|
        attempt = billing_attempts[bill.id]
        next unless attempt

        chargeback = BillStub.create!(
          type: 'Bill::Chargeback',
          subscription_id: bill.subscription_id,
          amount: bill.amount,
          description: 'Chargeback',
          created_at: attempt.created_at,
          bill_at: attempt.created_at,
          start_date: attempt.created_at,
          end_date: bill.end_date,
          status: 'chargedback',
        )

        bill.update!(status: 'paid', chargeback_id: chargeback.id)
        attempt.destroy
      end
    end
  end
end
