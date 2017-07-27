class CheckStaticScriptInstallation
  LIFETIME_TOTALS_PERIOD_IN_DAYS = 10

  # @param [Site] site
  def initialize(site)
    @site = site
  end

  def call
    script_installed! if not_really_uninstalled?
    script_uninstalled! if not_really_installed?
  end

  private

  attr_reader :site

  def not_really_uninstalled?
    !script_installed? && (script_installed_api? || script_installed_on_homepage?)
  end

  def not_really_installed?
    script_installed? && !(script_installed_api? || script_installed_on_homepage?)
  end

  def script_uninstalled!
    site.update(script_uninstalled_at: Time.current)
    Analytics.track(:site, site.id, 'Uninstalled')
    onboarding_track_script_uninstallation!
  end

  def script_installed!
    site.update(script_installed_at: Time.current)
    Referrals::RedeemForRecipient.run(site: site)
    Analytics.track(:site, site.id, 'Installed')
    onboarding_track_script_installation!
  end

  # has the script been installed according to the API?
  def script_installed_api?
    bar_statistics.values.any?(&:views?)
  end

  def script_installed_on_homepage?
    site_url_content.match(/#{ site.script_name }/).present? ||
      (site.had_wordpress_bars? && site_url_content.match(/hellobar\.js/).present?)
  rescue => _
    return false
  end

  def site_url_content
    @site_url_content ||= HTTParty.get(site.url, timeout: 5).body
  end

  def script_installed?
    site.script_installed_at.present? &&
      (site.script_uninstalled_at.blank? || site.script_installed_at > site.script_uninstalled_at)
  end

  def onboarding_track_script_installation!
    site.owners.each do |user|
      user.onboarding_status_setter.installed_script!
    end
  end

  def onboarding_track_script_uninstallation!
    site.owners.each do |user|
      user.onboarding_status_setter.uninstalled_script!
    end
  end

  # @return [Hash[Integer => BarStatistics]]
  # example:
  #   {site_element_id => BarStatistics}
  def bar_statistics
    @bar_statistics ||= FetchBarStatistics.new(site, days_limit: LIFETIME_TOTALS_PERIOD_IN_DAYS).call
  end
end
