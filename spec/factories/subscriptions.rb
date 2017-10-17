FactoryGirl.define do
  factory :subscription do
    site
    user nil
    schedule :monthly
    association :credit_card, factory: :credit_card
    amount 0.0

    trait :free do
      amount 0.0
      initialize_with { Subscription::Free.new(schedule: schedule) }
    end

    trait :free_plus do
      amount 0.0
      initialize_with { Subscription::FreePlus.new(schedule: schedule) }
    end

    trait :pro do
      amount { Subscription::Pro.defaults[schedule.to_sym == :monthly ? :monthly_amount : :yearly_amount] }
      initialize_with { Subscription::Pro.new(schedule: schedule) }
    end

    trait :pro_managed do
      initialize_with { Subscription::ProManaged.new(schedule: schedule) }
    end

    trait :pro_comped do
      initialize_with { Subscription::ProComped.new(schedule: schedule) }
    end

    trait :enterprise do
      amount { Subscription::Enterprise.defaults[schedule.to_sym == :monthly ? :monthly_amount : :yearly_amount] }
      initialize_with { Subscription::Enterprise.new(schedule: schedule) }
    end

    trait :with_bill do
      after :create do |subscription|
        create(:recurring_bill, :paid, subscription: subscription)
        subscription.reload
      end
    end

    trait :with_bills do
      after :create do |subscription|
        create_list :bill, 2, subscription: subscription
      end
    end

    trait :paid do
      after(:create) do |subscription|
        create :bill, :pro, :paid, subscription: subscription
        subscription.reload
      end
    end
  end
end
