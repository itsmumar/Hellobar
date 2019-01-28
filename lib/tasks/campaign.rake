namespace :campaign do
  desc 'check spam users'
  task verify_spam_campaigns: :environment do
    scope = Campaign.sent.unprocessed.where('sent_at > ?', 2.hours.ago)
    scope.find_each do |campaign|
      HandleSpamCampaign.new(campaign).call
    end
  end
end
