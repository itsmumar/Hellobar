FactoryGirl.define do
  factory :bar, parent: :site_element, class: 'Bar'

  factory :slider, parent: :site_element, class: 'Slider' do
    type 'Slider'
    placement 'top-left'
  end

  factory :alert, parent: :site_element, class: 'Alert'

  factory :modal, parent: :site_element, class: 'Modal' do
    placement nil
  end

  factory :takeover, parent: :site_element, class: 'Takeover' do
    placement nil
  end
end
