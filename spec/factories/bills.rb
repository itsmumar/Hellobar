FactoryGirl.define do
  factory :bill do
    amount 10
    subscription
    bill_at Time.current

    factory :pro_bill do
      amount Subscription::Pro.defaults[:monthly_amount]
      subscription { create :pro_subscription }
    end

    factory :free_bill do
      amount 0
      subscription { create :free_subscription }
    end

    factory :past_due_bill do
      amount 10
      bill_at { '2014-09-01'.to_date }
      subscription { create :pro_subscription }

      after :create do |bill|
        create :billing_attempt, :failed, bill: bill, payment_method_details: bill.subscription.payment_method.details.first
        bill.reload
      end
    end
  end

  factory :recurring_bill, parent: :bill, class: 'Bill::Recurring' do
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
end
