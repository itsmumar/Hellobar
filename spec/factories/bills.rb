FactoryGirl.define do
  factory :bill do
    amount 10
    subscription
    bill_at { Time.current }
    start_date { Time.current }
    end_date { 1.month.from_now }
    sequence(:authorization_code) { |n| "authorization-#{ n }" }

    factory :pro_bill do
      amount Subscription::Pro.defaults[:monthly_amount]
      subscription { create :subscription, :pro }

      after :create do |bill|
        create :billing_attempt, :success, bill: bill, payment_method_details: bill.subscription.payment_method.details.first
        bill.reload
      end
    end

    factory :free_bill do
      amount 0
      subscription { create :subscription, :free }
    end

    factory :past_due_bill do
      amount 10
      bill_at { '2014-09-01'.to_date }
      subscription { create :subscription, :pro }

      after :create do |bill|
        create :billing_attempt, :failed, bill: bill, payment_method_details: bill.subscription.payment_method.details.first
        bill.reload
      end
    end

    factory :recurring_bill, class: 'Bill::Recurring' do
    end

    factory :refund_bill, class: 'Bill::Refund' do
      amount(-10)
    end
  end

  trait :paid do
    status :paid
    after :create do |bill|
      create :billing_attempt, :success, bill: bill, payment_method_details: bill.subscription.payment_method.details.first
      bill.reload
    end
  end

  trait :voided do
    status :voided
  end

  trait :pending do
    status :pending
  end
end
