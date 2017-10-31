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

  # Find all pending bills which should be processed today
  def pending_bills
    Bill
      .where(status: [Bill::PENDING, Bill::FAILED])
      .where('? >= bill_at AND bill_at > ?', Time.current, Time.current - MAX_RETRY_TIME)
  end

  def handle(bill)
    return PayBill.new(bill).call if bill.amount.zero?
    return void(bill) if !bill.subscription || !bill.site
    return downgrade(bill) if expired? bill
    return skip(bill) if skip? bill

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
    if (days = days_since_first_billing_attempt(bill))
      days > MAX_RETRY_TIME
    else
      too_old?(bill)
    end
  end

  def too_old?(bill)
    bill.end_date < MAX_RETRY_TIME.ago
  end

  def days_since_first_billing_attempt(bill)
    days_since_billing_attempt bill.billing_attempts.first
  end

  def days_since_last_billing_attempt(bill)
    days_since_billing_attempt bill.billing_attempts.last
  end

  def days_since_billing_attempt(attempt)
    return unless attempt
    (Time.current.to_date - attempt.created_at.to_date) * 1.day
  end
end
