FactoryGirl.define do
  factory :subscription do
    site
  end

  factory :free_subscription, parent: :subscription, class: "Subscription::Free" do
    amount 0.0
    schedule :monthly
  end

  factory :pro_subscription, parent: :subscription, class: "Subscription::Pro" do
    schedule :monthly
    payment_method
  end
end
