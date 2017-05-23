namespace :email_digest do
  task deliver: :environment do
    Site.where(opted_in_to_email_digest: true).find_each do |site|
      SendDigestEmailJob.perform_later site
    end
  end
end
