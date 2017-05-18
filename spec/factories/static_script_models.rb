FactoryGirl.define do
  factory :static_script_rule, class: Hash do
    skip_create

    transient do
      rule
      site_elements { rule.active_site_elements }
    end

    initialize_with do
      {
        match: rule.match,
        conditions: rule.conditions.map { |c| create(:static_script_rule_condition, condition: c) },
        site_elements: site_elements
      }
    end
  end

  factory :static_script_rule_condition, class: Hash do
    skip_create

    transient do
      segment { condition.segment == 'CustomCondition' ? condition.custom_segment : condition.segment_key }
      condition
      settings { { segment: segment, operand: condition.operand, value: condition.value } }
    end

    initialize_with do
      if condition.timezone_offset.present?
        settings.merge(timezone_offset: condition.timezone_offset)
      else
        settings
      end
    end
  end

  factory :static_script_content_upgrade, class: Hash do
    skip_create

    transient do
      content_upgrade { create :content_upgrade }
    end

    initialize_with do
      {
        content_upgrade.id => {
          id: content_upgrade.id,
          type: content_upgrade.type,
          offer_headline: content_upgrade.offer_headline.to_s.gsub('{{', '<a href="#">').gsub('}}', '</a>'),
          caption: content_upgrade.caption,
          headline: content_upgrade.headline,
          disclaimer: content_upgrade.disclaimer,
          link_text: content_upgrade.link_text,
          email_placeholder: content_upgrade.email_placeholder,
          name_placeholder: content_upgrade.name_placeholder,
          contact_list_id: content_upgrade.contact_list_id,
          download_link: content_upgrade.content_upgrade_download_link
        }
      }
    end
  end
end
