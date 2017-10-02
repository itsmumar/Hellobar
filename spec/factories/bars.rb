FactoryGirl.define do
  factory :bar, parent: :site_element, class: 'Bar' do
    type 'Bar'
  end

  factory :slider, parent: :site_element, class: 'Slider' do
    type 'Slider'
    placement 'top-left'
  end

  factory :alert, parent: :site_element, class: 'Alert' do
    type 'Alert'
  end

  factory :modal, parent: :site_element, class: 'Modal' do
    type 'Modal'
    placement nil
  end

  factory :takeover, parent: :site_element, class: 'Takeover' do
    type 'Takeover'
    placement nil
  end
end
