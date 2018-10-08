FactoryBot.define do
  factory :site do
    transient do
      elements []
      user nil
      schedule :monthly
    end

    sequence(:url) { |i| "http://url-#{ i }.net" }

    after :create do |site, evaluator|
      create(:rule, site: site) if evaluator.elements.present?

      evaluator.elements.each do |element|
        create(:site_element, element, site: site)
      end

      site.users << evaluator.user if evaluator.user.present?
      site.reload
    end

    trait :with_bars do
      elements %i[email traffic]
    end

    trait :with_rule do
      after(:create) do |site|
        create(:rule, site: site)
      end
    end

    trait :with_user do
      after(:create) do |site|
        site.users << create(:user)
      end
    end

    trait :with_invoice_information do
      invoice_information "1 Melrose Place\n90210 Hollywood Blv, Ca"
    end

    trait :installed do
      script_installed_at Time.current
    end

    trait :free_subscription do
      after(:create) do |site, evaluator|
        create(:subscription, :free, site: site, schedule: evaluator.schedule)
      end
    end

    trait :with_paid_bill do
      after(:create) do |site, evaluator|
        subscription = create(
          :subscription,
          evaluator.subscription_plan,
          site: site,
          schedule: evaluator.schedule
        )

        bill = CalculateBill.new(subscription, bills: site.bills).call
        bill.pay!
        bill.save
      end
    end

    trait :pro do
      transient do
        subscription_plan :pro
      end

      with_paid_bill
    end

    trait :growth do
      transient do
        subscription_plan :growth
      end

      with_paid_bill
    end

    trait :free do
      transient do
        subscription_plan :free
      end

      with_paid_bill
    end

    trait :free_plus do
      transient do
        subscription_plan :free_plus
      end

      with_paid_bill
    end

    trait :elite do
      transient do
        subscription_plan :elite
      end

      with_paid_bill
    end

    trait :pro_managed do
      transient do
        subscription_plan :pro_managed
      end

      with_paid_bill
    end

    trait :pro_comped do
      transient do
        subscription_plan :pro_comped
      end

      with_paid_bill
    end

    trait :pro_special do
      transient do
        subscription_plan :pro_special
      end

      with_paid_bill
    end

    trait :custom_1 do
      transient do
        subscription_plan :custom_1
      end

      with_paid_bill
    end

    trait :custom_2 do
      transient do
        subscription_plan :custom_2
      end

      with_paid_bill
    end

    trait :custom_3 do
      transient do
        subscription_plan :custom_3
      end

      with_paid_bill
    end

    trait :past_due_site do
      after(:create) do |site|
        subscription = create(:subscription, :pro, site: site)
        create(:past_due_bill, subscription: subscription)
      end
    end
  end

  factory :site_capabilities, class: OpenStruct do
    skip_create

    remove_branding? { [true, false].sample }
    closable? { [true, false].sample }
    custom_targeted_bars? { [true, false].sample }
    at_site_element_limit? { [true, false].sample }
    custom_thank_you_text? { [true, false].sample }
    after_submit_redirect? { [true, false].sample }
    content_upgrades? { [true, false].sample }
    autofills? { [true, false].sample }
    geolocation_injection? { [true, false].sample }
    external_tracking? { [true, false].sample }
    alert_bars? { [true, false].sample }
    opacity? { [true, false].sample }
    advanced_themes? { [true, false].sample }
    precise_geolocation_targeting? { [true, false].sample }
  end

  sequence :content_upgrade_styles do
    {
      'offer_bg_color' => '#ffffb6',
      'offer_text_color' => '#000000',
      'offer_link_color' => '#1285dd',
      'offer_border_color' => '#000000',
      'offer_border_width' => '0px',
      'offer_border_style' => 'solid',
      'offer_border_radius' => '0px',
      'modal_button_color' => '#1285dd'
    }
  end
end
