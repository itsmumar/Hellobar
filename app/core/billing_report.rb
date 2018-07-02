class BillingReport
  include ActionView::Helpers::NumberHelper

  attr_reader :log

  def initialize(bills_count)
    @log = []
    @amount_successful = 0
    @amount_failed = 0
    @amount_skipped = 0
    @amount_downgraded = 0
    @num_failed = 0
    @num_successful = 0
    @num_skipped = 0
    @num_downgraded = 0
    @count = 0
    @bills_count = bills_count
  end

  def start
    info "#{ Rails.env }: #{ Time.current }"
    info '-' * 80
    info "Found #{ @bills_count } pending bills..."
  end

  def finish
    info '-' * 80
    info "#{ @num_successful } successful bills for #{ number_to_currency(@amount_successful) }"
    info "#{ @num_failed } failed bills for #{ number_to_currency(@amount_failed) }"
    info "#{ @num_skipped } skipped bills for #{ number_to_currency(@amount_skipped) }"
    info "#{ @num_downgraded } downgraded bills for #{ number_to_currency(@amount_downgraded) }"
    info "#{ @count } bills have been processed"
    info ''
    info ''
  end

  def interrupt(e)
    info '---- INTERRUPT ----'
    info e.inspect if e
    finish
  end

  def count
    @count += 1
    info "#{ @count } bills processed..." if !@count.zero? && @count % 500 == 0
  end

  def attempt(bill)
    @attempt = "Attempting to bill #{ bill.id }: #{ bill.subscription&.site&.url || 'NO SITE' } for #{ number_to_currency(bill.amount) }..."
    @bill = bill
    yield self
  rescue StandardError => e
    exception(e)
    Raven.capture_exception(e)
    raise
  ensure
    @bill = nil
    @attempt = nil
  end

  def cannot_pay(message = ' Cannot pay the bill')
    @amount_failed += @bill.amount
    @num_failed += 1
    info(@attempt + message)
  end

  def void(bill)
    info "Voiding bill #{ bill.id } because subscription or site not found"
  end

  def downgrade(bill)
    @amount_downgraded += bill.amount
    @num_downgraded += 1
    info "Voiding outdated bill #{ bill.id }"
    info "Downgrading site ##{ bill.site.id } #{ bill.site.url }"
  end

  def skip(bill, last_billing_attempt)
    @num_skipped += 1
    @amount_skipped += bill.amount
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
    post_to_slack msg if Settings.slack_channels['billing'].present?
    BillingLogger.info msg
    puts msg # rubocop:disable Rails/Output
  end

  def post_to_slack(msg)
    PostToSlack.new(:billing, text: msg).call
  rescue StandardError
    nil
  end

  def exception(e)
    info @attempt + ' ERROR' if @attempt.present?
    info "#{ e.class }: #{ e.message }\n  #{ e.backtrace.collect { |l| l.rjust(2) }.join("\n  ") }"
  end
end
