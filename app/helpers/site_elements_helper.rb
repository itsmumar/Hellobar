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
end
