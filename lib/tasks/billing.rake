namespace :billing do
  desc 'Runs the recurring billing'
  task :run => :environment do |t, args|
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
      @billing_report_log << msg
      File.open(File.join(Rails.root,"log", "billing.log"), "a"){|f| f.puts(msg)}
      puts msg
    end

    begin
      billing_report "#{Time.now}"
      billing_report "-"*80
      billing_report "Finding pending bills..."
      # Find all pending bills less than 30 days old
      pending_bills = Bill.where('? >= bill_at AND bill_at > ? AND status = ?', Time.now, now-MAX_RETRY_TIME, Bill.statuses[:pending])
      num_bills = pending_bills.length
      billing_report "Found #{num_bills} pending bills..."
      i = 0
      pending_bills.find_each do |bill|
        if i % 500 == 0
          billing_report "#{i} bills processed..."
        end
        i += 1
        if bill.amount == 0
          # Can mark it as paid
          bill.paid!
        else
          if !bill.subscription or !bill.subscription.site
            billing_report "Voiding bill #{bill.id} because subscription or site not found"
            bill.void!
          else
            # Try to bill the person if they haven't been within the last MIN_RETRY_TIME
            last_billing_attempt = bill.billing_attempts.last
            if last_billing_attempt and now - last_billing_attempt.created_at < MIN_RETRY_TIME
              billing_report "Not attempting bill #{bill.id} because last billing attempt was #{last_billing_attempt.created_at}"
            else
              # Attempt the billing
              msg = "Attempting to bill #{bill.id}: #{bill.subscription.site.url} for #{number_to_currency(bill.amount)}..."
              attempt = bill.attempt_billing!
              if attempt.success?
                num_successful += 1
                amount_successful += bill.amount
                billing_report(msg+"OK")
              else
                num_failed += 1
                amount_failed += bill.amount
                billing_report(msg+"Failed: #{attempt.response}")
              end
            end
          end
        end
      end
      billing_report "-"*80

      billing_report "#{num_successful} successful bills for #{number_to_currency(amount_successful)}"
      billing_report "#{num_failed} failed bills for #{number_to_currency(amount_failed)}"
      billing_report ""
      billing_report ""
    rescue Exception => e
      billing_report "#{e.class}: #{e.message}\n  #{e.backtrace.collect{|l| "  #{l}"}.join("\n  ")}"
      exit
    ensure
      emails = %w{imtall@gmail.com}
      Pony.mail({
        to: emails.join(", "),
        subject: "#{now.strftime("%Y-%m-%d")} - #{num_bills} bills processed for #{number_to_currency(amount_successful)} with #{num_failed} failures",
        body: @billing_report_log.collect{|l| "  #{l}"}.join("\n")
      })
    end
  end
end