FactoryBot.define do
  factory :bill, class: 'Bill::Recurring' do
    amount 10
    subscription
    type 'Bill::Recurring'
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
      status Bill::FAILED

      after :create do |bill|
        create :billing_attempt, :failed, bill: bill, credit_card: bill.credit_card
        bill.reload
      end
    end

    factory :recurring_bill, class: 'Bill::Recurring' do
    end

    factory :refund_bill, class: 'Bill::Refund' do
      amount(-10)
      subscription
      type 'Bill::Refund'
      refunded_bill { create :bill, :pro, subscription: subscription }
      refunded_billing_attempt { refunded_bill.billing_attempts.last }

      trait :refunded do
        status Bill::REFUNDED
      end
    end

    trait :pro do
      amount { Subscription::Pro.defaults[:monthly_amount] }
      subscription { create :subscription, :pro }

      after :create do |bill|
        create :billing_attempt, :success,
          bill: bill, response: 'authorization',
          credit_card: bill.credit_card

        bill.reload
      end
    end

    trait :enterprise do
      amount { Subscription::Enterprise.defaults[:monthly_amount] }
      subscription { create :subscription, :enterprise }

      after :create do |bill|
        create :billing_attempt, :success,
          bill: bill, response: 'authorization',
          credit_card: bill.credit_card

        bill.reload
      end
    end

    trait :paid do
      status Bill::PAID
      after :create do |bill|
        create :billing_attempt, :success, bill: bill, credit_card: bill.credit_card
        bill.reload
      end
    end

    trait :voided do
      status Bill::VOIDED
    end

    trait :pending do
      status Bill::PENDING
    end

    trait :failed do
      status Bill::FAILED
    end

    trait :with_attempt do
      after :create do |bill|
        create :billing_attempt, :failed, bill: bill, credit_card: bill.credit_card
      end
    end
  end
end
