class Bill
  class Refund < self
    belongs_to :refunded_billing_attempt, class_name: 'BillingAttempt', inverse_of: :refunds
    has_one :refunded_bill, class_name: 'Bill', dependent: :restrict_with_exception

    # Refunds must be a negative amount
    def check_amount
      raise InvalidBillingAmount, "Amount must be negative. It was #{ amount.to_f }" if amount > 0
    end
  end
end
