FactoryGirl.define do
  factory :whitelabel do
    domain 'hellobar.com'
    subdomain 'email.hellobar.com'

    site
  end
end
