module SiteElementsHelper
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

  def icon_class_for_element(element)
    case element.element_subtype
    when "email"
      "icon-contacts"
    when /social\//
      "icon-social"
    when "traffic"
      "icon-clicks"
    end
  end

  def site_element_views(metrics)
    metrics ? metrics[0][0] : 0
  end

  def site_element_conversions(metrics)
    metrics ? metrics[0][1] : 0
  end

  def site_element_conversion_percentage(metrics)
    if metrics.nil? || metrics[0][1] == 0
      percentage = 0.0
    else
      percentage = metrics[0][0] * 1.0 / metrics[0][1]
    end


    "#{(percentage * 100).round(1)}%"
  end
end
