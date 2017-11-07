class PayRecurringBills
  MIN_RETRY_TIME = 3.days
  MAX_RETRY_TIME = 27.days

  # Find all pending bills which should be processed today
  # BETWEEN is inclusive on both sides
  # and equivalent to the expression (min <= expr AND expr <= max)
  def self.bills
    Bill
      .where(status: [Bill::PENDING, Bill::FAILED])
      .where('DATE(bill_at) <= ?', Date.current)
  end

  def initialize
    @report = BillingReport.new(self.class.bills.count)
  end

  def call
    report.start

    # find_each is not advised to be used here
    # as it could lead to endless looping
    self.class.bills.each do |bill|
      report.count
      handle bill
    end

    report.finish
  rescue Exception => e # rubocop: disable Lint/RescueException
    # handle `kill` or `Ctrl + C`
    Raven.capture_exception(e)
    report.interrupt(e)
    raise
  ensure
    report.email
  end

  private

  attr_reader :report

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
        cannot_pay(bill)
      end
    end
  end

  def pay(bill)
    bill = PayBill.new(bill).call

    if bill.paid?
      report.success
    else
      handle_failed_attempt bill
    end
  end

  def handle_failed_attempt(bill)
    report.fail bill.billing_attempts.last&.response
    BillingMailer.could_not_charge(bill).deliver_later
  end

  def cannot_pay(bill)
    report.cannot_pay
    BillingMailer.no_credit_card(bill).deliver_later
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
