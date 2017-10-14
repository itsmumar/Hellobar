FactoryGirl.define do
  factory :embed_code, class: String do
    skip_create
    provider 'my_emma'

    initialize_with do
      Rails.root.join('spec', 'support', 'embed_code', "#{ provider }.html").read
    end
  end
end
