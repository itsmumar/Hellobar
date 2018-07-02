class AddStatusTextToBillingAttempts < ActiveRecord::Migration
  def up
    add_column :billing_attempts, :status_text, :string, default: 'pending', null: false
    BillingAttempt.where(status: 1).update_all status_text: 'failed'
    BillingAttempt.where(status: 0).update_all status_text: 'successful'
  end

  def down
    BillingAttempt.where(status_text: 'failed').update_all status: 1
    BillingAttempt.where(status_text: 'successful').update_all status: 0
    remove_column :billing_attempts, :status_text
  end
end
