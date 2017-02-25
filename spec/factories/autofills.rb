FactoryGirl.define do
  factory :autofill do
    name 'Email'
    listen_selector 'input.email'
    populate_selector 'input.email'

    site
  end
end
