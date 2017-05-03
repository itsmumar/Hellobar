namespace :email_digest do
  task deliver: :environment do
    Site.where(opted_in_to_email_digest: true).find_each do |site|
      site.queue_digest_email(queue_name: Hellobar::Settings[:low_priority_queue])
    end
  end
end
