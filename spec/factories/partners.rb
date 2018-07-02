FactoryBot.define do
  factory :partner do
    first_name 'John'
    last_name 'Galt'
    sequence(:email) { |n| "partner#{ n }@email.com" }
    sequence(:website_url) { |n| "http://partner-site#{ n }.com" }
    sequence(:affiliate_identifier) { |n| "partner#{ n }" }
    partner_plan_id { PartnerPlan.all.first.id }
    require_credit_card false
  end
end
