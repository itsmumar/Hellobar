module SiteElementsHelper
  A_OFFSET = "A".ord

  def total_conversion_text(site_element)
    if site_element.element_subtype == "announcement"
      "--"
    else
      number_with_delimiter(site_element.total_conversions)
    end
  end

  def conversion_percent_text(site_element)
    if site_element.element_subtype == "announcement"
      "n/a"
    else
      number_to_percentage(site_element.conversion_percentage * 100, precision: 1)
    end
  end

  def site_element_activity_units(elements, opts = {})
    units = [*elements].map do |element|
      case element.element_subtype
      when "traffic"
        {:unit => "click"}
      when "email"
        {:unit => "email", :verb => "collected"}
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
    end
  end

  def style_icon_class_for_element(element)
    if element.type.downcase == 'bar'
      'icon-bar'
    else
      'icon-modal'
    end
  end

  def site_element_subtypes_for_site(site)
    return [] unless site
    site.site_elements.collect(&:element_subtype)
  end

  def recent_activity_message(element)
    views, conversions = element.total_views, element.total_conversions

    message = "<strong>"
    message += link_to "The #{element.short_subtype} bar you added #{time_ago_in_words(element.created_at)} ago", site_site_elements_path(element.site) << "#site_element_#{element.id}"
    message += "</strong>"

    # how many conversions has this site element resulted in?
    if element.is_announcement?
      return "#{message} has already resulted in #{number_with_delimiter(element.total_views)} views.".html_safe
    elsif element.has_converted?
      conversion_description = site_element_activity_units([element], :plural => conversions > 1, :verb => true)
      message << " has already resulted in #{number_with_delimiter(conversions)} #{conversion_description}."
    else
      return # no conversions, so just be quiet about it.
    end

    elements_in_group = element.site.site_elements.where.not(:id => element.id).select{ |e| e.short_subtype == element.short_subtype }

    # how is this site element converting relative to others with the same subtype?
    unless elements_in_group.empty?
      group_views, group_conversions = elements_in_group.inject([0, 0]) do |sum, group_element|
        [sum[0] + group_element.total_views, sum[1] + group_element.total_conversions]
      end

      conversion_rate = conversions * 1.0 / views
      group_conversion_rate = group_conversions * 1.0 / group_views

      # dont provide lift number when lift is infinite
      unless [group_conversion_rate, conversion_rate].any?(&:infinite?)
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

        message << " your other #{element.short_subtype} bars."
      end # infinity check

      # is the result significant or not?
      if difference_is_significant?([element] + elements_in_group)
        message << " This result is statistically significant."
      else
        message << " We don't have enough data yet to know if this is significant."
      end
    end

    message.html_safe
  end

  def ab_test_icon(site_element)
    elements_in_group = site_element.rule.site_elements.select { |se| se.paused == false && se.short_subtype == site_element.short_subtype && se.type == site_element.type}
    elements_in_group.sort! { |a, b| a.created_at <=> b.created_at }
    index = elements_in_group.index(site_element)

    # site element is paused, its the only site element in the group, or something wacky is going on
    if index.nil? || elements_in_group.size == 1
      return "<i class='testing-icon icon-abtest'></i>".html_safe
    end

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
      (elements["Modal"] || []) + (elements["Takeover"] || [])
    ].compact
  end

  def elements_grouped_by_subtype(elements)
    social_elements = elements.select { |x| x.element_subtype.include?("social") }
    elements = elements.group_by(&:element_subtype)

    [elements["email"], social_elements, elements["traffic"], elements["announcement"]].compact
  end
end
