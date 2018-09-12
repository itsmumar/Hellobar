FactoryBot.define do
  factory :bill do
    amount 10
    subscription
    bill_at { Time.current }
    start_date { Time.current }
    end_date { 1.month.from_now }
    sequence(:authorization_code) { |n| "authorization-#{ n }" }
    grace_period_allowed true

    trait :free do
      amount 0
      subscription { create :subscription, :free }
    end

    factory :past_due_bill do
      amount 10
      bill_at { '2014-09-01'.to_date }
      subscription { create :subscription, :pro }
      status Bill::STATE_FAILED

      after :create do |bill|
        create :billing_attempt, :failed, bill: bill, credit_card: bill.subscription.credit_card
        bill.reload
      end
    end

    trait :pro do
      amount { Subscription::Pro.defaults[:monthly_amount] }
      subscription { create :subscription, :pro }

      after :create do |bill|
        create :billing_attempt, :success,
          bill: bill, response: 'authorization',
          credit_card: bill.subscription.credit_card

        bill.reload
      end
    end

    trait :elite do
      amount { Subscription::Elite.defaults[:monthly_amount] }
      subscription { create :subscription, :elite }

      after :create do |bill|
        create :billing_attempt, :success,
          bill: bill, response: 'authorization',
          credit_card: bill.subscription.credit_card

        bill.reload
      end
    end

    trait :paid do
      status Bill::STATE_PAID
      after :create do |bill|
        create :billing_attempt, :success, bill: bill, credit_card: bill.subscription.credit_card
        bill.reload
      end
    end

    trait :voided do
      status Bill::STATE_VOIDED
    end

    trait :pending do
      status Bill::STATE_PENDING
    end

    trait :failed do
      status Bill::STATE_FAILED
    end

    trait :with_attempt do
      after :create do |bill|
        create :billing_attempt, :failed, bill: bill, credit_card: bill.subscription.credit_card
      end
    end
  end
end
