FactoryGirl.define do
  factory :lead do
    user

    industry { 'ecommerce' }
    job_role { 'CTO' }
    company_size { '10-25' }
    estimated_monthly_traffic { '1000-100000' }
    first_name { 'FirstName' }
    last_name { 'LastName' }
    challenge { Lead::CHALLENGES.sample }
    interested false

    trait :interested do
      interested true
      phone_number '+1123456789'
    end
  end
end
