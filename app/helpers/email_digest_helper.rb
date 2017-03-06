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

  def self.date_of_previous(day)
    date  = Date.parse(day)
    delta = date > Date.today ? 7 : 0
    date - delta
  end

  def self.template_name(site)
    if site.script_installed_at.nil?
      'New Email Digest (Not Installed)'
    elsif site.script_installed_at > 1.week.ago
      if site.is_free?
        'New Email Digest (First Time)'
      else
        'New Email Digest (First Time, Pro)'
      end
    else
      if site.is_free?
        'New Email Digest'
      else
        'New Email Digest (Pro)'
      end
    end
  end
end
