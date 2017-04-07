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

    trait :interesting do
      interesting true
      phone_number '+1123456789'
    end

    trait :empty do
      to_create { |instance| instance.save!(validate: false) }
      industry {}
      job_role {}
      company_size {}
      estimated_monthly_traffic {}
      first_name {}
      last_name {}
      challenge {}
    end
  end
end
