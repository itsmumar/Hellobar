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

    trait :with_bills do
      after :create do |subscription|
        create_list :bill, 2, subscription: subscription
      end
    end
  end

  factory :free_subscription, parent: :subscription, class: 'Subscription::Free' do
    amount 0.0
    schedule :monthly

    association :payment_method, factory: [:payment_method, :success]
  end

  factory :pro_subscription, parent: :subscription, class: 'Subscription::Pro' do
    schedule :monthly

    association :payment_method, factory: [:payment_method, :success]
  end

  factory :enterprise_subscription, parent: :subscription, class: 'Subscription::Enterprise' do
    schedule :monthly

    association :payment_method, factory: [:payment_method, :success]
  end
end
