FactoryGirl.define do
  factory :site_element do
    rule
    type "Bar"
    element_subtype "announcement"

    factory :modal_element do
      type "Modal"
    end

    factory :takeover_element do
      type "Takeover"
    end
  end
end
