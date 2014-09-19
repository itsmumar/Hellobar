module SitesHelper
  def display_url_for_site(site)
    URI.parse(site.url).host
  rescue URI::InvalidURIError
    site.url
  end

  def segment_description(segment_and_value)
    segment, value = segment_and_value.split(":", 2)
    user_segment = Hello::Segments::User.find{ |d| d[:key] == segment }
    "#{user_segment[:name]} is #{value}"
  end

  def create_targeted_content_link(site, segment)
    segment, value = segment.split(":", 2)
    segment = Condition::SEGMENTS.find { |s| s[1] == segment }

    return "" unless segment.present? # the API returned a segment key which we don't implement

    segment = segment[1]
    existing_rule = rule_for_segment_and_value(site, segment, value)

    path = if existing_rule
      new_site_site_element_path(site, anchor: "/settings?rule_id=#{existing_rule.id}")
    else
      new_site_site_element_path(site, anchor: "/targeting?segment=#{segment}&value=#{value}")
    end

    link_to "Create targeted content", path, class: "button"
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
end
