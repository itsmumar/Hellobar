FactoryBot.define do
  factory :whitelabel do
    domain 'hellobar.com'
    subdomain 'email'

    sequence :domain_identifier

    site

    dns [{ cname: 'cname', valid: false }]
  end
end
