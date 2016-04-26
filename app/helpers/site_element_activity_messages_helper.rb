module SiteElementActivityMessagesHelper
  def initial_message_text(element)
    message = "<strong>"
    message += link_to "The #{element.short_subtype} bar you added #{time_ago_in_words(element.created_at)} ago", site_site_elements_path(element.site, anchor: "site_element_#{element.id}")
    message += "</strong>"
    message
  end

  def append_number_of_units_text_to_message(element, message)
    number_of_units = site_element_activity_units([element], :plural => element.total_conversions > 1, :verb => true)
    message << " has already resulted in #{number_with_delimiter(element.total_conversions)} #{number_of_units}."
    message
  end

  def append_number_of_views_text_to_message(element, message)
    message = "#{message} has already resulted in #{number_with_delimiter(element.total_views)} views."
    message
  end

  def append_comparison_text_to_message(element, conversion_rate, group_conversion_rate, message)
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
    message
  end

  def append_significance_text_to_message(element, related_site_elements, message)
    # is the result significant or not?
    if difference_is_significant?([element] + related_site_elements)
      message << " This result is statistically significant."
    else
      message << " We don't have enough data yet to know if this is significant."
    end
    message
  end

  def append_conversion_text_to_message(element, related_site_elements, message)
    group_views, group_conversions = related_site_elements.inject([0, 0]) do |sum, group_element|
      [sum[0] + group_element.total_views, sum[1] + group_element.total_conversions]
    end
    conversion_rate = element.total_conversions * 1.0 / element.total_views
    group_conversion_rate = group_conversions * 1.0 / group_views

    # dont provide lift number when lift is infinite
    unless [group_conversion_rate, conversion_rate].any?(&:infinite?)
      message = append_comparison_text_to_message(element, conversion_rate, group_conversion_rate, message)
    end
    message = append_significance_text_to_message(element, related_site_elements, message)
    message
  end

  def activity_message(element)
    message = initial_message_text(element)

    if element.has_converted?
      message = append_number_of_units_text_to_message(element, message)
      related_site_elements = element.related_site_elements
      unless related_site_elements.empty?
        message = append_conversion_text_to_message(element, related_site_elements, message)
      end
    elsif element.is_announcement?
      message = append_number_of_views_text_to_message(element, message)
    else
      return # no conversions, so just be quiet about it.
    end

    message.html_safe
  end
end
