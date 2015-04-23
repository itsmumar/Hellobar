module EmailDigestHelper
  def formatted_percent(percent)
    str = "#{percent}%"
    if percent > 0
      "+#{str}"
    else
      str
    end
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
