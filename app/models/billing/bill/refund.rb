require 'billing_log'

class Bill
  class Refund < self
    # Refunds must be a negative amount
    def check_amount
      raise InvalidBillingAmount, "Amount must be negative. It was #{ amount.to_f }" if amount > 0
    end

    # Refunds are never considered "active"
    def active_during(_date)
      false
    end

    def refunded_billing_attempt
      unless @refunded_billing_attempt
        if refunded_billing_attempt_id
          @refunded_billing_attempt = BillingAttempt.find(refunded_billing_attempt_id)
        end
      end
      @refunded_billing_attempt
    end

    def refunded_billing_attempt_id
      return metadata['refunded_billing_attempt_id'] if metadata
    end

    def refunded_billing_attempt=(billing_attempt)
      self.refunded_billing_attempt_id = billing_attempt.id
    end

    def refunded_billing_attempt_id=(id)
      self.metadata = {} unless metadata
      metadata['refunded_billing_attempt_id'] = id
      @refunded_billing_attempt = nil
    end
  end
end
