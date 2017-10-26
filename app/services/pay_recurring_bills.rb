class PayRecurringBills
  MIN_RETRY_TIME = 3.days
  MAX_RETRY_TIME = 27.days

  def initialize
    @report = BillingReport.new(pending_bills.count)
  end

  def call
    report.start

    pending_bills.find_each do |bill|
      report.count
      handle bill
    end

    report.finish
  ensure
    report.email
  end

  private

  attr_reader :report

  # Find all pending bills less than 30 days old
  def pending_bills
    Bill.where(status: [Bill::PENDING, Bill::FAILED])
  end

  def handle(bill)
    return PayBill.new(bill).call if bill.amount.zero?
    return void(bill) if !bill.subscription || !bill.site
    return skip(bill) if !expired?(bill) && skip?(bill)
    return downgrade(bill) if expired? bill

    # Try to bill the person if he/she hasn't been within the last MIN_RETRY_TIME

    report.attempt bill do
      if bill.can_pay?
        pay bill
      else
        report.cannot_pay
      end
    end
  end

  def pay(bill)
    bill = PayBill.new(bill).call
    if bill.paid?
      report.success
    else
      report.fail bill.billing_attempts.last&.response
    end
  end

  def void(bill)
    report.void bill
    bill.voided!
  end

  def skip(bill)
    report.skip bill, bill.billing_attempts.last
  end

  def downgrade(bill)
    report.downgrade bill
    bill.voided!
    ChangeSubscription.new(bill.site, subscription: 'free').call
  end

  def skip?(bill)
    days = days_since_last_billing_attempt(bill)
    days && days < MIN_RETRY_TIME
  end

  def expired?(bill)
    days = days_since_first_billing_attempt(bill)
    days && days > MAX_RETRY_TIME
  end

  def days_since_first_billing_attempt(bill)
    first_billing_attempt = bill.billing_attempts.first
    return unless first_billing_attempt
    (Time.current.to_date - first_billing_attempt.created_at.to_date) * 1.day
  end

  def days_since_last_billing_attempt(bill)
    last_billing_attempt = bill.billing_attempts.last
    return unless last_billing_attempt
    (Time.current.to_date - last_billing_attempt.created_at.to_date) * 1.day
  end
end
