namespace :onboarding_campaigns do
  desc 'Deliver all onboarding campaigns'
  task deliver: :environment do
    DeliverOnboardingCampaigns.new.call
  end
end
