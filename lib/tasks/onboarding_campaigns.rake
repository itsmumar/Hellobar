namespace :onboarding_campaigns do
  desc 'Deliver all onboarding campaigns'
  task deliver: :environment do
    UserOnboardingCampaign.deliver_all_onboarding_campaign_email!
  end
end
