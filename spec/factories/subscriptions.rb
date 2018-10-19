FactoryBot.define do
  factory :subscription do
    site
    schedule Subscription::MONTHLY
    association :credit_card, factory: :credit_card
    amount 0.0

    trait :monthly

    trait :yearly do
      schedule Subscription::YEARLY
    end

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

    trait :growth do
      amount { Subscription::Growth.defaults[schedule.to_sym == :monthly ? :monthly_amount : :yearly_amount] }
      initialize_with { Subscription::Growth.new(schedule: schedule) }
    end

    trait :pro_managed do
      initialize_with { Subscription::ProManaged.new(schedule: schedule) }
    end

    trait :pro_comped do
      initialize_with { Subscription::ProComped.new(schedule: schedule) }
    end

    trait :pro_special do
      amount { Subscription::ProSpecial.defaults[schedule.to_sym == :monthly ? :monthly_amount : :yearly_amount] }
      initialize_with { Subscription::ProSpecial.new(schedule: schedule) }
    end

    trait :elite do
      amount { Subscription::Elite.defaults[schedule.to_sym == :monthly ? :monthly_amount : :yearly_amount] }
      initialize_with { Subscription::Elite.new(schedule: schedule) }
    end

    trait :elite_special do
      amount { Subscription::EliteSpecial.defaults[schedule.to_sym == :monthly ? :monthly_amount : :yearly_amount] }
      initialize_with { Subscription::EliteSpecial.new(schedule: schedule) }
    end

    trait :custom_0 do
      amount { Subscription::Custom0.defaults[schedule.to_sym == :monthly ? :monthly_amount : :yearly_amount] }
      initialize_with { Subscription::Custom0.new(schedule: schedule) }
    end

    trait :custom_1 do
      amount { Subscription::Custom1.defaults[schedule.to_sym == :monthly ? :monthly_amount : :yearly_amount] }
      initialize_with { Subscription::Custom1.new(schedule: schedule) }
    end

    trait :custom_2 do
      amount { Subscription::Custom2.defaults[schedule.to_sym == :monthly ? :monthly_amount : :yearly_amount] }
      initialize_with { Subscription::Custom2.new(schedule: schedule) }
    end

    trait :custom_3 do
      amount { Subscription::Custom3.defaults[schedule.to_sym == :monthly ? :monthly_amount : :yearly_amount] }
      initialize_with { Subscription::Custom3.new(schedule: schedule) }
    end

    trait :with_bill do
      after :create do |subscription|
        create(:bill, :paid, subscription: subscription)
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
