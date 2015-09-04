FactoryGirl.define do
  factory :rule do
    site
    name "test rule"
    match "all"
  end
end
