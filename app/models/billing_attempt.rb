class BillingAttempt < ActiveRecord::Base
  belongs_to :bill
  belongs_to :payment_method_details
  enum status: [:success, :failed]

  def readonly?
    new_record? ? false : true
  end
end
