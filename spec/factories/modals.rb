FactoryBot.define do
  factory :modal, parent: :site_element, class: 'Modal' do
    type 'Modal'
    placement nil
  end
end
