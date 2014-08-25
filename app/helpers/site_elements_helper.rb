module SiteElementsHelper
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
      when "social/share_on_linkedin"
        {:unit => "share"}
      when "social/plus_one_on_google_plus"
        {:unit => "plus one"}
      when "social/pin_on_pinterest"
        {:unit => "pin"}
      when "social/follow_on_pinterest"
        {:unit => "follower", :verb => "gained"}
      when "social/share_on_buffer"
        {:unit => "share"}
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

  def site_element_subtypes_for_site(site)
    return [] unless site
    site.site_elements.collect(&:element_subtype)
  end

  def site_element_views(metrics)
    number_with_delimiter(metrics ? metrics.last[0] : 0)
  end

  def site_element_conversions(metrics)
    number_with_delimiter(metrics ? metrics.last[1] : 0)
  end

  def site_element_conversion_percentage(metrics)
    if metrics.nil? || metrics.last[1] == 0
      percentage = 0.0
    else
      percentage = metrics.last[1] * 1.0 / metrics.last[0]
    end

    "#{(percentage * 100).round(1)}%"
  end

  def recent_activity_message(element, totals)
    views, conversions = totals[element.id.to_s].try(:last) || [0, 0]

    message = "<strong>The #{element.short_subtype} bar you added #{time_ago_in_words(element.created_at)} ago</strong>"

    if conversions == 0
      conversion_description = site_element_activity_units([element], :plural => true, :verb => true)
      return "#{message} hasn't resulted in any #{conversion_description} yet.".html_safe
    else
      conversion_description = site_element_activity_units([element], :plural => conversions > 1, :verb => true)
      message << " has already resulted in #{number_with_delimiter(conversions)} #{conversion_description}."
    end

    message.html_safe
  end
end
