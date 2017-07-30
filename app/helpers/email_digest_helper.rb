module EmailDigestHelper
  def formatted_percent(percent, include_sign = true)
    precision = 3
    precision = 2 if percent.abs >= 1 && percent.abs < 100
    number_to_human(percent, format: include_sign && percent > 0 ? '+%n%' : '%n%', precision: precision)
  end

  def conversion_header(site_elements)
    types = site_elements.map { |se| SiteElement::BAR_TYPES[se.element_subtype] }.uniq
    types.count == 1 ? types.first : 'Conversions'
  end

  def format_number(num)
    precision = 3
    precision = 2 if num >= 1_000 && num < 100_000

    number_to_human(num, units: { thousand: 'k', million: 'm', billion: 'b' }, format: '%n%u', precision: precision)
  end

  def reason_for_element(site_element)
    case site_element.short_subtype
    when 'traffic'
      'driving traffic.'
    when 'email'
      'collecting emails.'
    when 'social'
      'driving social media traffic.'
    when 'call'
      'receiving calls.'
    else
      'involving users.'
    end
  end

  def self.date_of_previous(day)
    date = Date.parse(day)
    delta = date > Date.current ? 7 : 0
    date - delta
  end

  def self.last_week
    last_sunday = date_of_previous('Sunday')
    6.days.until(last_sunday)..last_sunday
  end

  def last_week
    EmailDigestHelper.last_week
  end

  def week_for_subject
    start_date = last_week.first
    end_date = last_week.last
    end_date_format = start_date.month == end_date.month ? '%-d, %Y' : '%b %-d, %Y'
    from = start_date.strftime('%b %-d')
    till = end_date.strftime(end_date_format)
    "#{ from } - #{ till }"
  end

  def tracker_param(*args)
    Hello::TrackingParam.encode_tracker(*args)
  end
end
