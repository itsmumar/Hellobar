FactoryGirl.define do
  factory :slider, parent: :site_element, class: 'Slider' do
    type 'Slider'
    placement 'top-left'
  end
end
