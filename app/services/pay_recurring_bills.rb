class PayRecurringBills
  MIN_RETRY_TIME = 3.days
  MAX_RETRY_TIME = 30.days

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
    Bill
      .where(status: [Bill::PENDING, Bill::FAILED])
      .where('? >= bill_at AND bill_at > ?', Time.current, Time.current - MAX_RETRY_TIME)
  end

  def handle(bill)
    return PayBill.new(bill).call if bill.amount.zero?
    return void(bill) if !bill.subscription || !bill.site
    return if skip? bill

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
    bill.update! status: Bill::VOID
  end

  def skip?(bill)
    # Try to bill the person if they haven't been within the last MIN_RETRY_TIME
    last_billing_attempt = bill.billing_attempts.last
    no_retry = last_billing_attempt && Time.current - last_billing_attempt.created_at < MIN_RETRY_TIME

    report.skip bill, last_billing_attempt if no_retry

    no_retry
  end
end
