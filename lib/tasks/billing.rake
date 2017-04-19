namespace :billing do
  desc 'Runs the recurring billing'
  task run: :environment do |_t, _args|
    include ActionView::Helpers::NumberHelper

    MIN_RETRY_TIME = 3.days
    MAX_RETRY_TIME = 30.days
    now = Time.now
    amount_successful = 0
    amount_failed = 0
    num_failed = 0
    num_successful = 0

    @billing_report_log = []

    def billing_report(msg)
      return unless msg
      @billing_report_log << msg
      File.open(Rails.root.join('log', 'billing.log'), 'a') { |f| f.puts(msg) }
      puts msg
    end

    msg = nil

    begin
      lock_file_path = Rails.root.join('tmp', 'billing.lock')
      lock_file = File.open(lock_file_path, File::RDWR | File::CREAT, 0644)
      result = lock_file.flock(File::LOCK_EX | File::LOCK_NB)
      if result == false
        raise 'Could not get lock, process already running likely..'
      end
      # Write this Process ID
      lock_file.write(Process.pid.to_s)
      lock_file.fdatasync
      # Check the pid to make sure we have the lock
      sleep 3
      lock_file_pid = File.read(lock_file_path).to_i
      raise "Expected #{ Process.pid } but was #{ lock_file_pid.inspect }, so exiting" unless lock_file_pid == Process.pid
      billing_report 'PID matched'
      billing_report Time.now.to_s
      billing_report '-' * 80
      billing_report 'Finding pending bills...'
      # Find all pending bills less than 30 days old
      pending_bills = Bill.where('? >= bill_at AND bill_at > ? AND status = ?', Time.now, now - MAX_RETRY_TIME, Bill.statuses[:pending])
      num_bills = pending_bills.length
      billing_report "Found #{ num_bills } pending bills..."
      i = 0
      pending_bills.find_each do |bill|
        billing_report "#{ i } bills processed..." if i % 500 == 0
        i += 1
        if bill.amount == 0
          # Can mark it as paid
          bill.paid!
        elsif !bill.subscription || !bill.subscription.site
          billing_report "Voiding bill #{ bill.id } because subscription or site not found"
          bill.void!
        else
          # Try to bill the person if they haven't been within the last MIN_RETRY_TIME
          last_billing_attempt = bill.billing_attempts.last
          no_retry = last_billing_attempt && now - last_billing_attempt.created_at < MIN_RETRY_TIME

          if no_retry
            billing_report "Not attempting bill #{ bill.id } because last billing attempt was #{ last_billing_attempt.created_at }"
            next
          end

          # Attempt the billing
          msg = "Attempting to bill #{ bill.id }: #{ bill.subscription.site.url } for #{ number_to_currency(bill.amount) }..."
          if (bill.amount != 0) && bill.subscription.payment_method && (!bill.subscription.payment_method.current_details || !bill.subscription.payment_method.current_details.token)
            num_failed += 1
            amount_failed += bill.amount
            billing_report(msg + 'Skipped: no payment method details available')
          elsif (bill.amount != 0) && !bill.subscription.payment_method
            num_failed += 1
            amount_failed += bill.amount
            billing_report(msg + 'Skipped: no payment method available')
          else
            attempt = bill.attempt_billing!
            if (attempt == true) || attempt.success?
              num_successful += 1
              amount_successful += bill.amount
              billing_report(msg + 'OK')
            else
              num_failed += 1
              amount_failed += bill.amount
              billing_report(msg + "Failed: #{ attempt.response }")
            end
          end
        end
      end
      billing_report '-' * 80

      billing_report "#{ num_successful } successful bills for #{ number_to_currency(amount_successful) }"
      billing_report "#{ num_failed } failed bills for #{ number_to_currency(amount_failed) }"
      billing_report ''
      billing_report ''
    rescue => e
      billing_report(msg.to_s + 'ERROR')
      billing_report "#{ e.class }: #{ e.message }\n  #{ e.backtrace.collect { |l| "  #{ l }" }.join("\n  ") }"
      exit
    ensure
      stage = Hellobar::Settings[:env_name]
      if Rails.env.production? && (stage == 'production')
        emails = %w[mailmanager@hellobar.com]
        Pony.mail(
          to: emails.join(', '),
          subject: "#{ now.strftime('%Y-%m-%d') } - #{ num_bills } bills processed for #{ number_to_currency(amount_successful) } with #{ num_failed } failures",
          body: @billing_report_log.collect { |l| "  #{ l }" }.join("\n")
        )
      end
    end
  end
end
