FactoryGirl.define do
  factory :site_element do
    rule
    type "Bar"
    element_subtype "announcement"

    factory :modal_element do
      type "Modal"
    end
  end
end
