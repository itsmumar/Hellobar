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
    debug_install('UNINSTALLED')
    site.update(script_uninstalled_at: Time.current)
    Analytics.track(:site, site.id, 'Uninstalled')
    onboarding_track_script_uninstallation!
  end

  def script_installed!
    debug_install('INSTALLED')
    site.update(script_installed_at: Time.current)
    Referrals::RedeemForRecipient.run(site: site)
    Analytics.track(:site, site.id, 'Installed')
    onboarding_track_script_installation!
  end

  # has the script been installed according to the API?
  def script_installed_api?
    data = lifetime_totals
    return false if data.blank?

    data.values.any? do |days|
      days_with_views = days.select { |(views, _conversions)| views > 0 }.count

      # site element was installed in the last n days
      (days_with_views > 0 && days_with_views < LIFETIME_TOTALS_PERIOD_IN_DAYS) ||
        # site element received views in the last n days
        (days.count >= LIFETIME_TOTALS_PERIOD_IN_DAYS && days[-LIFETIME_TOTALS_PERIOD_IN_DAYS][0] < days.last[0])
    end
  end

  def script_installed_on_homepage?
    site_url_content =~ /#{ site.script_name }/ ||
      (site.had_wordpress_bars? && site_url_content =~ /hellobar\.js/)
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

  # TODO: get rid of this?
  # We are getting bad analytics data regarding installs and uninstalls
  # When I analyzed the data the samples were 90-99% inaccurate. Looking
  # at the code I can not see any obvious error. I'm adding this logging
  # to collect more data so that hopefully I can find the source of the
  # problem and then implement an appropriate fix.
  def debug_install(type)
    lines = ["[#{ Time.current }] #{ type } - Site[#{ site.id }] script_installed_at: #{ site.script_installed_at.inspect }, script_uninstalled_at: #{ site.script_uninstalled_at.inspect }, lifetime_totals: #{ lifetime_totals.inspect }"]
    caller(0..4).each do |line|
      lines << "\t#{ line }"
    end

    File.open(Rails.root.join('log', 'debug_install.log'), 'a') do |file|
      file.puts(lines.join("\n"))
    end
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

  # @return [Hash[String => Array]]
  # example:
  #   {site_element_id => [
  #     [yesterday's views_number, yesterday's conversions_number],
  #     [today's views_number, today's conversions_number]
  #   ]}
  def lifetime_totals
    @lifetime_totals ||= site.lifetime_totals(days: LIFETIME_TOTALS_PERIOD_IN_DAYS)
  end
end
