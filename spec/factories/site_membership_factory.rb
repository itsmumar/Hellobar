FactoryGirl.define do
  factory :site_membership do
    role 'owner'
    site
    user

    factory :site_ownership do
      role 'owner'
    end
  end
end
