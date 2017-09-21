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
    factory :bar, class: 'Bar'

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

    trait :alert do
      type 'Alert'
    end

    factory :content_upgrade, class: 'ContentUpgrade' do
      type 'ContentUpgrade'
      element_subtype 'email'
      contact_list

      content_upgrade_pdf { File.new(Rails.root.join('spec', 'fixtures', 'content_upgrade.pdf')) }

      offer_headline 'offer_headline'
      caption 'caption'
      headline 'headline'
      name_placeholder 'name_placeholder'
      email_placeholder 'email_placeholder'
      link_text 'link_text'
      disclaimer 'disclaimer'

      # thank you content
      thank_you_enabled true
      thank_you_headline 'thank_you_headline'
      thank_you_subheading 'thank_you_subheading'
      thank_you_cta 'thank_you_cta'
      thank_you_url 'http://www.hellobar.com/'
    end

    trait :custom do
      type 'Custom'
    end

    factory :modal_element do
      type 'Modal'
      placement nil
    end

    factory :takeover_element, class: Takeover do
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
        fields %w[email phone name]
      end

      settings do
        fields_to_collect = fields.each_with_index.map do |field, index|
          if field =~ /name|email|phone/
            { id: "some-long-id-#{ index }", type: "builtin-#{ field }", is_enabled: true }.stringify_keys
          else
            { id: "some-long-id-#{ index }", type: 'text', label: field, is_enabled: true }.stringify_keys
          end
        end

        {
          fields_to_collect: fields_to_collect
        }
      end
    end

    trait :with_active_image do
      active_image { create(:image_upload, :with_valid_image, site: site) }
    end

    after :create do |element, evaluator|
      element.update! rule: evaluator.site.rules.first! if evaluator.site
    end
  end

  factory :site_element_for_rule, class: Hash do
    site_element

    skip_create
    initialize_with do
      id = site_element.id
      contact_list_id = site_element.contact_list_id
      {
        'animated' => true, 'background_color' => 'eb593c', 'border_color' => 'ffffff', 'button_color' => '000000',
        'email_placeholder' => 'Your email', 'headline' => 'Hello, HelloBar!', 'image_placement' => 'bottom',
        'link_color' => 'ffffff', 'link_style' => 'button', 'link_text' => 'Click Here', 'name_placeholder' => 'Your name',
        'placement' => 'bar-top', 'show_border' => false, 'show_branding' => true, 'size' => 'large', 'text_color' => 'ffffff',
        'texture' => 'none', 'theme_id' => 'classic', 'type' => 'Bar', 'view_condition' => 'immediately', 'wiggle_button' => false,
        'blocks' => [], 'use_question' => false, 'font' => "'Open Sans',sans-serif", 'google_font' => 'Open+Sans',
        'branding_url' => "http://www.hellobar.com?sid=#{ id }", 'closable' => false,
        'contact_list_id' => contact_list_id, 'email_redirect' => false, 'hide_destination' => true, 'id' => id,
        'open_in_new_window' => false, 'primary_color' => 'eb593c', 'pushes_page_down' => true,
        'remains_at_top' => true, 'secondary_color' => '000000',
        'settings' => { 'fields_to_collect' => [{ 'type' => 'builtin-email', 'is_enabled' => true }] },
        'subtype' => 'email', 'tab_side' => 'right', 'template_name' => 'bar_email',
        'thank_you_text' => "'Thank you for signing up! If you would like this sort of bar on your site...'",
        'updated_at' => 1491936487000.0, 'use_free_email_default_msg' => true, 'wiggle_wait' => 0,
        'theme' => {
          'name' => 'Hello Bar Classic', 'type' => 'generic', 'id' => 'classic', 'default_theme' => true,
          'fonts' => %w[open_sans source_pro helvetica arial georgia],
          'element_types' => %w[Bar Modal Slider Takeover],
          'defaults' => {
            'Bar' => {
              'background_color' => 'E8562A', 'text_color' => 'FFFFFF', 'button_color' => '000000',
              'link_color' => 'FFFFFF', 'font_id' => 'open_sans'
            },
            'Slider' => {
              'background_color' => 'FFFFFF',
              'text_color' => '5c5e60', 'button_color' => 'E8562A', 'link_color' => 'FFFFFF', 'font_id' => 'open_sans'
            },
            'Modal' => {
              'background_color' => 'FFFFFF', 'text_color' => '5c5e60', 'button_color' => 'E8562A',
              'link_color' => 'FFFFFF', 'font_id' => 'open_sans'
            },
            'Takeover' => {
              'background_color' => 'FFFFFF', 'text_color' => '5c5e60', 'button_color' => 'E8562A',
              'link_color' => 'FFFFFF', 'font_id' => 'open_sans'
            },
            'Alert' => {
              'background_color' => 'ffffff', 'triger_color' => 'ffffff', 'text_color' => '5c5e60',
              'button_color' => 'e8562a', 'link_color' => 'ffffff', 'font_id' => 'open_sans'
            }
          },
          'image' => {
            'upload_copy' => 'Recommended minimum is 750 x 900',
            'position_default' => 'left',
            'position_selectable' => true
          },
          'directory' => 'lib/themes/hellobar-classic'
        },
        'views' => 0,
        'conversions' => 0,
        'conversion_rate' => 0,
        'notification_delay' => 10,
        'sound' => 'none',
        'trigger_color' => '31b5ff',
        'trigger_icon_color' => 'ffffff'
      }
    end
  end

  factory :site_element_external_events, class: Array do
    skip_create

    site_element
    category 'Hello Bar'
    label { "#{ site_element.type }-#{ site_element.id }" }
    types { %w[view click] + ["#{ site_element.short_subtype }_conversion"] }

    initialize_with do
      types.map do |type|
        {
          id: site_element.id,
          category: category,
          label: label,
          type: type,
          action: { 'view' => 'View', 'click' => 'Click' }.fetch(type, 'Conversion')
        }
      end
    end
  end
end
