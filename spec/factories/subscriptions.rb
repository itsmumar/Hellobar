FactoryGirl.define do
  factory :subscription do
    site
    user
    schedule :monthly
    association :payment_method, factory: %i[payment_method success]

    trait :free do
      amount 0.0
      initialize_with { Subscription::Free.new }
    end

    trait :free_plus do
      amount 0.0
      initialize_with { Subscription::FreePlus.new }
    end

    trait :pro do
      initialize_with { Subscription::Pro.new }
    end

    trait :pro_managed do
      initialize_with { Subscription::ProManaged.new }
    end

    trait :pro_comped do
      initialize_with { Subscription::ProComped.new }
    end

    trait :enterprise do
      initialize_with { Subscription::Enterprise.new }
    end

    trait :problem_with_payment do
      initialize_with { Subscription::ProblemWithPayment.new }
    end

    trait :with_bills do
      after :create do |subscription|
        create_list :bill, 2, subscription: subscription
      end
    end
  end
end
