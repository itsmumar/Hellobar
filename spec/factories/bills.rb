FactoryGirl.define do
  factory :bill do
    amount 0
    subscription
    bill_at Time.now

    factory :pro_bill do
      amount Subscription::Pro.defaults[:monthly_amount]
      association :subscription, factory: :pro_subscription
    end
  end

  factory :recurring_bill, parent: :bill, class: 'Bill::Recurring' do
  end
end
