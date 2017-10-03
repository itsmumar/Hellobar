FactoryGirl.define do
  factory :takeover, parent: :site_element, class: 'Takeover' do
    type 'Takeover'
    placement nil
  end
end
