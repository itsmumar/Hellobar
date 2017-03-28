FactoryGirl.define do
  factory :site_element, class: SiteElement do
    transient do
      site nil
    end

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

    trait :with_blocks do
      blocks [
        { 'id' => 'headline_first', 'content' => { 'text' => '<strong>Grow your blog traffic by</strong>' } },
        { 'id' => 'headline_second', 'content' => { 'text' => '<strong>300%</strong>' } },
        { 'id' => 'headline_third', 'content' => { 'text' => '<strong>with our free tool</strong>' } }
      ]
    end

    trait :geolocation do
      headline '<p>
        Country: <span data-hb-geolocation="country"></span>,
        City: <span data-hb-geolocation="city"></span></p>'
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

    trait :call do
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

    trait :email_with_redirect do
      element_subtype 'email'
      settings do
        {
          fields_to_collect: [
            {
              type: 'builtin-email',
              is_enabled: true
            }
          ],
          after_email_submit_action: SiteElement::AFTER_EMAIL_ACTION_MAP.invert[:redirect]
        }
      end

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

    trait :with_custom_fields do
      transient do
        fields ['email', 'phone', 'name']
      end

      settings do
        fields_to_collect = fields.each_with_index.map do |field, index|
          { id: "some-long-id-#{ index }", type: "builtin-#{field}", is_enabled: true }.stringify_keys
        end

        {
          fields_to_collect: fields_to_collect
        }
      end
    end

    after :create do |element, evaluator|
      element.update! rule: evaluator.site.rules.first! if evaluator.site
    end
  end
end
