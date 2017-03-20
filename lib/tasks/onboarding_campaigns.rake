namespace :onboarding_campaigns do
  task deliver: :environment do
    UserOnboardingCampaign.deliver_all_onboarding_campaign_email
  end
end
