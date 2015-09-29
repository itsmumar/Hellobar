FactoryGirl.define do
  factory :subscription do
    site
  end

  factory :pro_subscription, parent: :subscription, class: "Subscription::Pro" do
    schedule :monthly
    payment_method
  end
end
