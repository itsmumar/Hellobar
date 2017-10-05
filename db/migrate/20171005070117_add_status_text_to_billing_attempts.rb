class AddStatusTextToBillingAttempts < ActiveRecord::Migration
  def change
    add_column :billing_attempts, :status_text, :string
    BillingAttempt.where(status: 1).update_all status_text: 'failed'
    BillingAttempt.where(status: 0).update_all status_text: 'success'
  end
end
