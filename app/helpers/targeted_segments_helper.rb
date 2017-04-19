module TargetedSegmentsHelper
  SALT = '7f9d074257b1400c55d0b838d8e7f5bdd8330151'.freeze

  def create_targeted_content_link(site, targeted_segment)
    segment, value = targeted_segment.split(':', 2)
    segment = Condition::SEGMENTS.find { |s| s[1] == segment }

    return '' if segment.blank? # the API returned a segment key which we don't implement

    segment = segment[1]
    existing_rule = rule_for_segment_and_value(site, segment, value)

    if existing_rule
      path = new_site_site_element_path(site, anchor: "/settings?rule_id=#{ existing_rule.id }")
      method = :get
    else
      token = generate_segment_token(targeted_segment)
      path = site_targeted_segments_path(site, targeted_segment: { token: token, segment: targeted_segment })
      method = :post
    end

    link_options = {
      method: site.capabilities.at_site_element_limit? ? nil : method, # if method is set, browser will follow link despite our restriction-enforcing javascript
      'data-prompt-upgrade' => site.capabilities.at_site_element_limit?,
      'data-upgrade-benefit' => 'create more bars'
    }

    link_to 'Create targeted content', path, { class: 'button' }.merge(link_options)
  end

  def rule_for_segment_and_value(site, segment, value)
    site.rules.includes(:conditions).find do |rule|
      condition = rule.conditions.first
      segment_data = condition.try(:segment_data)

      rule.conditions.count == 1 &&
        segment_data[:key] == segment &&
        condition.value == value
    end
  end

  def generate_segment_token(segment)
    Digest::SHA1.hexdigest("#{ SALT }#{ segment }")
  end

  def segment_description(segment_and_value)
    segment, value = segment_and_value.split(':', 2)
    user_segment = Hello::Segments::User.find { |d| d[:key] == segment }
    "#{ user_segment[:name] } is #{ value }"
  end
end
