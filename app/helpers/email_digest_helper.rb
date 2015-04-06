module EmailDigestHelper
  def formatted_percent_with_wrapper(percent, opts = {})
    if percent.nil? || percent == 0
      style = "color: gray"
      direction = nil
    elsif percent > 0
      style = "color: green"
      direction = "+"
    else
      style = "color: red"
      direction = nil
    end

    if percent.nil?
      formatted = "n/a%"
    else
      formatted = number_to_percentage(percent * 100, :precision => 2)
    end

    "<span style=\"#{style}\">".tap do |output|
      output << "(" if opts[:parens]
      output << direction if direction
      output << formatted
      output << ")" if opts[:parens]

      output << "</span>"
    end.html_safe
  end

  def self.template_name(site)
    if site.script_installed_at.nil?
      "New Email Digest (Not Installed)"
    elsif site.script_installed_at > 1.week.ago
      if site.is_free?
        "New Email Digest (First Time)"
      else
        "New Email Digest (First Time, Pro)"
      end
    else
      if site.is_free?
        "New Email Digest"
      else
        "New Email Digest (Pro)"
      end
    end
  end
end
