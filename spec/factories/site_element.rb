FactoryGirl.define do
  factory :rule do
    name "Everyone"
    match "all"
    editable false
    site
  end

  factory :site_element do
    type "Bar"
    element_subtype "announcement"
    rule
  end
end
