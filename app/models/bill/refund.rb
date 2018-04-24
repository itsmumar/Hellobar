class Bill
  class Refund < self
    has_one :refunded_bill, class_name: 'Bill', dependent: :restrict_with_exception, inverse_of: :refund

    # Refunds must be a negative amount
    def check_amount
      raise InvalidBillingAmount, "Amount must be negative. It was #{ amount.to_f }" if amount > 0
    end

    private

    def can_status_be_changed?(value)
      super || value == REFUNDED
    end
  end
end
