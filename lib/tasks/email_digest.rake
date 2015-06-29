namespace :email_digest do
  task :deliver => :environment do
    if Hellobar::Settings[:deliver_email_digests]
      Site.where(:opted_in_to_email_digest => true).find_each do |site|
        next unless user = site.owner

        site.queue_digest_email(queue_name: Hellobar::Settings[:low_priority_queue])
      end
    end
  end
end
