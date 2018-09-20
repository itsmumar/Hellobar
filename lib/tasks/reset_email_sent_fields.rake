namespace :reset_email_sent_fields do
  desc 'Reset the warning_email_sent fields on sites'
  task run: :environment do
    Site.active.where(warning_email_one_sent: true).find_in_batches do |group|
      group.each do |site|
        ResetEmailSentFields.new(site).call
        HandleUnfreezeFrozenAccount.new(site).call
      end
    end
  end
end
