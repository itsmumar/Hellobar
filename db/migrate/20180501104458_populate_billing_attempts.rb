class PopulateBillingAttempts < ActiveRecord::Migration
  class BillStub < ActiveRecord::Base
    self.table_name = :bills
    self.inheritance_column = :_type
  end

  class BillingAttemptStub < ActiveRecord::Base
    self.table_name = :billing_attempts
  end

  def up
    BillStub.where(type: 'Bill::Refund').find_each do |refund|
      BillingAttemptStub.create!(
        bill_id: refund.id,
        response: refund.authorization_code,
        status: refund.status == 'refunded' ? 'successful' : 'failed',
        action: 'refund',
        created_at: refund.created_at
      )
    end

    BillStub.where(type: 'Bill::Chargeback').find_each do |chargeback|
      BillingAttemptStub.create!(
        bill_id: chargeback.id,
        status: 'successful',
        action: 'chargeback',
        created_at: chargeback.created_at
      )
    end
  end

  def down
    BillingAttemptStub.where(action: %w[refund chargeback]).destroy_all
  end
end
