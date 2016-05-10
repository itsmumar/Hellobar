class ConversionActivityMessage < ActivityMessage
  def body
    message = append_number_of_units_text_to_message(self.site_element, super)
    related_site_elements = self.site_element.related_site_elements
    unless related_site_elements.empty?
      message = append_conversion_text_to_message(self.site_element, related_site_elements, message)
    end
    message
  end

  private

  def append_number_of_units_text_to_message(site_element, message)
    number_of_units = site_element_activity_units([site_element], :plural => site_element.total_conversions > 1, :verb => true)
    message << " has already resulted in #{number_with_delimiter(site_element.total_conversions)} #{number_of_units}."
    message
  end

  def append_conversion_text_to_message(site_element, related_site_elements, message)
    conversion_rate = site_element.conversion_rate
    group_conversion_rate = SiteElement.group_conversion_rate(related_site_elements)
    # dont provide lift number when lift is infinite
    unless [group_conversion_rate, conversion_rate].any?(&:infinite?)
      message = append_comparison_text_to_message(site_element, conversion_rate, group_conversion_rate, message)
    end
    message = append_significance_text_to_message(site_element, related_site_elements, message)
    message
  end

  def append_comparison_text_to_message(site_element, conversion_rate, group_conversion_rate, message)
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

  def append_significance_text_to_message(site_element, related_site_elements, message)
    # is the result significant or not?
    if difference_is_significant?([site_element] + related_site_elements)
      message << " This result is statistically significant."
    else
      message << " We don't have enough data yet to know if this is significant."
    end
    message
  end
end
