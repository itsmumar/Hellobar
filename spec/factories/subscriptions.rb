FactoryGirl.define do
  factory :subscription do
    site
    user

    trait :free do
      initialize_with { Subscription::Free.new }
    end

    trait :pro do
      initialize_with { Subscription::Pro.new }
    end

    trait :pro_managed do
      initialize_with { Subscription::ProManaged.new }
    end
  end

  factory :free_subscription, parent: :subscription, class: "Subscription::Free" do
    amount 0.0
    schedule :monthly
    payment_method
  end

  factory :pro_subscription, parent: :subscription, class: "Subscription::Pro" do
    schedule :monthly
    payment_method
  end

  factory :enterprise_subscription, parent: :subscription, class: "Subscription::Enterprise" do
    schedule :monthly
    payment_method
  end
end
