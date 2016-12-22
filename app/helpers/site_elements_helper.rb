module SiteElementsHelper
  A_OFFSET = "A".ord

  def activity_message_for_conversion(site_element, related_site_elements)
    message = ""
    message = activity_message_append_number_of_units(site_element, message)
    unless related_site_elements.empty?
      message = activity_message_append_conversion_text(site_element, related_site_elements, message)
    end
    message
  end

  def activity_message_append_number_of_units(site_element, message)
    number_of_units = site_element_activity_units([site_element], :plural => site_element.total_conversions > 1, :verb => true)
    message << " has already resulted in #{number_with_delimiter(site_element.total_conversions)} #{number_of_units}."
    message
  end

  def activity_message_append_conversion_text(site_element, related_site_elements, message)
    unless [site_elements_group_conversion_rate(related_site_elements), site_element.conversion_rate].any?(&:infinite?)
      message = activity_message_append_comparison_text(site_element, site_element.conversion_rate, site_elements_group_conversion_rate(related_site_elements), message)
    end
    message = activity_message_append_significance_text(site_element, related_site_elements, message)
    message
  end

  def activity_message_append_comparison_text(site_element, conversion_rate, group_conversion_rate, message)
    message << " Currently this bar is converting"
    if conversion_rate > group_conversion_rate
      lift = (conversion_rate - group_conversion_rate) / group_conversion_rate
      message << " #{number_to_percentage(lift * 100, :precision => 1)}" unless lift.infinite?
      message << " better than"
    elsif group_conversion_rate > conversion_rate
      lift = (group_conversion_rate - conversion_rate) / conversion_rate
      message << " #{number_to_percentage(lift * 100, :precision => 1)}" unless lift.infinite?
      message << " worse than"
    else
      message << " exactly as well as"
    end
    message << " your other #{site_element.short_subtype} bars."
    message
  end

  def activity_message_append_significance_text(site_element, related_site_elements, message)
    if difference_is_significant?([site_element] + related_site_elements)
      message << " This result is statistically significant."
    else
      message << " We don't have enough data yet to know if this is significant."
    end
    message
  end

  def site_elements_group_view_count(site_elements)
    site_elements.to_a.sum(&:total_views)
  end

  def site_elements_group_conversion_count(site_elements)
    site_elements.to_a.sum(&:total_conversions)
  end

  def site_elements_group_conversion_rate(site_elements)
    site_elements_group_conversion_count(site_elements) * 1.0 / site_elements_group_view_count(site_elements)
  end

  def total_conversion_text(site_element)
    site_element.element_subtype == "announcement" ? "--" : number_with_delimiter(site_element.total_conversions)
  end

  def conversion_percent_text(site_element)
    site_element.element_subtype == "announcement" ? "n/a" : number_to_percentage(site_element.conversion_percentage * 100, precision: 1)
  end

  def site_element_activity_units(elements, opts = {})
    units = [*elements].map do |element|
      case element.element_subtype
      when "traffic"
        {:unit => "click"}
      when "email"
        {:unit => "email", :verb => "collected"}
      when "call"
        {:unit => "call"}
      when "announcement"
        {:unit => "view"}
      when "social/tweet_on_twitter"
        {:unit => "tweet"}
      when "social/follow_on_twitter"
        {:unit => "follower", :verb => "gained"}
      when "social/like_on_facebook"
        {:unit => "like"}
      when "social/share_on_linkedin", "social/share_on_buffer"
        {:unit => "share"}
      when "social/plus_one_on_google_plus"
        {:unit => "plus one"}
      when "social/pin_on_pinterest"
        {:unit => "pin"}
      when "social/follow_on_pinterest"
        {:unit => "follower", :verb => "gained"}
      else
        raise "#{element.element_subtype} not configured in this helper"
      end
    end
    unit = units.uniq.size == 1 ? units.first[:unit] : "conversion"
    verb = units.uniq.size == 1 ? units.first[:verb] : nil
    pluralized_unit = unit.pluralize(opts[:plural] ? 2 : 1)
    verb && opts[:verb] ? "#{pluralized_unit} #{verb}" : pluralized_unit
  end

  def site_element_age(site_element)
    age = Time.now - site_element.created_at
    if age < 1.minute
      units = [(age / 1.second).to_i, "second"]
    elsif age < 1.hour
      units = [(age / 1.minute).to_i, "minute"]
    elsif age < 1.day
      units = [(age / 1.hour).to_i, "hour"]
    elsif age < 1.year
      units = [(age / 1.day).to_i, "day"]
    else
      units = [(age / 1.year).to_i, "year"]
    end
    "#{units[0]} <small>#{units[1].pluralize(units[0])} old</small>".html_safe
  end

  def type_icon_class_for_element(element)
    case element.element_subtype
    when "email"
      "icon-contacts"
    when "announcement"
      "icon-megaphone"
    when /social\//
      "icon-social"
    when "traffic"
      "icon-clicks"
    when "call"
      "icon-call"
    end
  end

  def style_icon_class_for_element(element)
    element.type.downcase == 'bar' ? 'icon-bar' : 'icon-modal'
  end

  def site_element_subtypes_for_site(site)
    return [] unless site
    site.site_elements.collect(&:element_subtype)
  end

  def ab_test_icon(site_element)
    elements_in_group = site_element.rule.site_elements.select { |se| se.paused == false && se.short_subtype == site_element.short_subtype && se.type == site_element.type}
    elements_in_group.sort! { |a, b| a.created_at <=> b.created_at }
    index = elements_in_group.index(site_element)
    # site element is paused, its the only site element in the group, or something wacky is going on
    return "<i class='testing-icon icon-abtest'></i>".html_safe if index.nil? || elements_in_group.size == 1
    letter = (index + A_OFFSET).chr
    winner = elements_in_group.max_by(&:conversion_percentage)
    if difference_is_significant?(elements_in_group) && site_element == winner
      "<i class='testing-icon icon-tip #{site_element.short_subtype}'><span class='numbers'>#{letter}</span></i>".html_safe
    else
      "<i class='testing-icon icon-circle #{site_element.short_subtype}'><span class='numbers'>#{letter}</span></i>".html_safe
    end
  end

  def difference_is_significant?(elements)
    values = {}
    elements.each_with_index do |element, i|
      values[element.id] = {
        :views => element.total_views,
        :conversions => element.total_conversions
      }
    end
    ABAnalyzer::ABTest.new(values).different?
  rescue ABAnalyzer::InsufficientDataError
    false
  end

  def activity_units_for_improve_suggestion(name)
    case name
    when "email" then "emails"
    when "traffic" then "clicks"
    else "conversions"
    end
  end

  def elements_grouped_by_type(elements)
    elements = elements.group_by(&:type)
    [
      elements["Bar"],
      elements["Slider"],
      (elements["Modal"] || []) + (elements["Takeover"] || []),
      elements["Custom"]
    ].compact
  end

  def elements_grouped_by_subtype(elements)
    social_elements = elements.select { |x| x.element_subtype.include?("social") }
    elements = elements.group_by(&:element_subtype)
    [elements["email"], social_elements, elements["traffic"], elements["call"], elements["announcement"]].compact
  end

  def render_headline(site_element)
    # Condering `blocks` field will be present only for `templates`
    headline = if site_element.blocks.present?
                 h = ''
                 site_element.blocks.each do |block|
                   h += "#{block['content']['text']} " if block['id'].include?('headline')
                 end
                 h
               else
                 site_element.headline || ''
               end

    strip_tags(site_element.use_question? ? site_element.question : headline).html_safe
  end
end
