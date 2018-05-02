class RemoveRefundsAndChargebacks < ActiveRecord::Migration
  class BillStub < ActiveRecord::Base
    self.table_name = :bills
    self.inheritance_column = :_type
  end

  class BillingAttemptStub < ActiveRecord::Base
    self.table_name = :billing_attempts
  end

  def up
    BillStub.where(type: 'Bill::Refund').find_each do |refund|
      bill = BillStub.find_by(refund_id: refund.id)
      billing_attempt = BillingAttemptStub.where(bill_id: refund.id).order(:id).last

      next unless bill && billing_attempt

      BillStub.transaction do
        billing_attempt.update!(bill_id: bill.id)
        bill.update!(status: 'refunded', status_set_at: refund.created_at)
        refund.destroy
      end
    end

    BillStub.where(type: 'Bill::Chargeback').find_each do |chargeback|
      bill = BillStub.find_by(chargeback_id: chargeback.id)
      billing_attempt = BillingAttemptStub.where(bill_id: chargeback.id).order(:id).last

      next unless bill && billing_attempt

      BillStub.transaction do
        billing_attempt.update!(bill_id: bill.id)
        bill.update!(status: 'chargedback', status_set_at: chargeback.created_at)
        chargeback.destroy
      end
    end
  end

  def down
    BillStub.where(status: 'refunded').find_each do |bill|
      billing_attempt = BillingAttemptStub.where(bill_id: bill.id, action: 'refund').order(:id).last

      next unless billing_attempt

      BillStub.transaction do
        refund = BillStub.create!(
          type: 'Bill::Refund',
          subscription_id: bill.subscription_id,
          amount: bill.amount,
          description: 'Refund due to customer service request',
          created_at: billing_attempt.created_at,
          bill_at: billing_attempt.created_at,
          start_date: billing_attempt.created_at,
          end_date: bill.end_date,
          status: billing_attempt.status == 'successful' ? 'refunded' : 'voided',
          authorization_code: billing_attempt.response
        )

        bill.update!(status: 'paid', refund_id: refund.id)
        billing_attempt.update!(bill_id: refund.id)
      end
    end

    BillStub.where(status: 'chargedback').find_each do |bill|
      billing_attempt = BillingAttemptStub.where(bill_id: bill.id, action: 'chargeback').order(:id).last

      next unless billing_attempt

      BillStub.transaction do
        chargeback = BillStub.create!(
          type: 'Bill::Chargeback',
          subscription_id: bill.subscription_id,
          amount: bill.amount,
          description: 'Chargeback',
          created_at: billing_attempt.created_at,
          bill_at: billing_attempt.created_at,
          start_date: billing_attempt.created_at,
          end_date: bill.end_date,
          status: 'chargedback',
        )

        bill.update!(status: 'paid', chargeback_id: chargeback.id)
        billing_attempt.update!(bill_id: chargeback.id)
      end
    end
  end
end
