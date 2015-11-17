FactoryGirl.define do
  factory :site_element do
    rule
    type "Bar"
    element_subtype "announcement"

    factory :bar_element, class: "Bar" do
      type "Bar"
    end

    factory :modal_element, class: 'Modal' do
      type "Modal"
    end

    factory :takeover_element, class: 'Takeover' do
      type "Takeover"
    end
  end
end
