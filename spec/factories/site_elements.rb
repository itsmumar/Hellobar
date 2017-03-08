FactoryGirl.define do
  factory :site_element do
    type 'Bar'
    theme_id 'classic'
    element_subtype 'announcement'
    headline 'Hello, HelloBar!'
    placement 'bar-top'

    rule

    trait :bar

    trait :slider do
      type 'Slider'
      placement 'top-left'
    end

    factory :modal_element do
      type 'Modal'
      placement nil
    end

    factory :takeover_element do
      type 'Takeover'
      placement nil
    end

    trait :click_to_call do
      element_subtype 'call'
      phone_number '1-367-399-4120'
    end

    trait :traffic do
      element_subtype 'traffic'
    end

    trait :email do
      element_subtype 'email'
      settings Hash[fields_to_collect: [{ type: 'builtin-email', is_enabled: true }]]

      contact_list
    end

    trait :twitter do
      element_subtype 'social/tweet_on_twitter'
    end

    trait :facebook do
      element_subtype 'social/like_on_facebook'
    end

    trait :closable do
      closable true
    end
  end
end
