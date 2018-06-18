FactoryBot.define do
  factory :partner do
    first_name 'John'
    last_name 'Galt'
    sequence(:email) { |n| "partner#{ n }@email.com" }
    sequence(:website_url) { |n| "http://partner-site#{ n }.com" }
    sequence(:affiliate_identifier) { |n| "partner#{ n }" }
    plan { PartnerPlan.all.first }
  end
end
