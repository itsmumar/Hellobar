FactoryGirl.define do
  factory :whitelabel do
    domain 'hellobar.com'
    subdomain 'email'

    site
  end
end
