FactoryGirl.define do
  factory :bar, parent: :site_element, class: 'Bar' do
    type 'Bar'
  end
end
