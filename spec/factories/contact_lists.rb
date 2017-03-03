FactoryGirl.define do
  factory :contact_list do
    site
    name "My List"

    trait :with_tags do
      data({ "tags" => %w(id1 id2) })
    end
  end
end
