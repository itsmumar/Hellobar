FactoryGirl.define do
  factory :data_api_contact, class: Array do
    skip_create

    transient do
      sequence(:email) { |i| "contact#{ i }@email.com" }
    end

    initialize_with do
      [
        email,
        'FirstName LastName',
        Time.now.to_i
      ]
    end
  end
end
