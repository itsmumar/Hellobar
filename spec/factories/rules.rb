FactoryGirl.define do
  factory :rule do
    name 'test rule'
    match 'all'

    site
  end
end
