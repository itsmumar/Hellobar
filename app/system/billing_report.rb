class BillingReport
  include ActionView::Helpers::NumberHelper

  attr_reader :log

  def initialize(bills_count)
    @log = []
    @amount_successful = 0
    @amount_failed = 0
    @num_failed = 0
    @num_successful = 0
    @count = 0
    @bills_count = bills_count
  end

  def start
    info Time.current.to_s
    info '-' * 80
    info "Found #{ @bills_count } pending bills..."
  end

  def finish
    info '-' * 80
    info "#{ @num_successful } successful bills for #{ number_to_currency(@amount_successful) }"
    info "#{ @num_failed } failed bills for #{ number_to_currency(@amount_failed) }"
    info ''
    info ''
  end

  def count
    @count += 1
    info "#{ @count } bills processed..." if !@count.zero? && @count % 500 == 0
  end

  def attempt(bill)
    @attempt = "Attempting to bill #{ bill.id }: #{ bill.subscription&.site&.url || 'NO SITE' } for #{ number_to_currency(bill.amount) }..."
    @bill = bill
    yield
  rescue => e
    exception(e)
    Raven.capture_exception(e)
    raise
  ensure
    @bill = nil
    @attempt = nil
  end

  def cannot_pay
    @amount_failed += @bill.amount
    @num_failed += 1
    info(@attempt + ' Skipped: no credit card available')
  end

  def void(bill)
    info "Voiding bill #{ bill.id } because subscription or site not found"
  end

  def skip(bill, last_billing_attempt)
    info "Not attempting bill #{ bill.id } because last billing attempt was #{ last_billing_attempt.created_at }"
  end

  def fail(msg)
    @amount_failed += @bill.amount
    @num_failed += 1
    info("#{ @attempt } Failed: #{ msg }")
  end

  def success
    @amount_successful += @bill.amount
    @num_successful += 1
    info(@attempt + ' OK')
  end

  def email
    return if Rails.env.development?

    emails =
      if Rails.env.production?
        %w[mailmanager@hellobar.com]
      else
        %w[dev@hellobar.com]
      end

    Pony.mail(
      to: emails.join(', '),
      subject: "#{ Time.current.strftime('%Y-%m-%d') } - #{ @bills_count } bills processed for #{ number_to_currency(@amount_successful) } with #{ @num_failed } failures",
      body: @log.map { |l| "  #{ l }" }.join("\n")
    )
  end

  private

  def info(msg)
    log << msg
    BillingLogger.info msg
    puts msg # rubocop:disable Rails/Output
  end

  def exception(e)
    info @attempt + ' ERROR' if @attempt.present?
    info "#{ e.class }: #{ e.message }\n  #{ e.backtrace.collect { |l| l.rjust(2) }.join("\n  ") }"
  end
end
