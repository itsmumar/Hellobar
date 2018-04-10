class UpdateStaticScriptInstallation
  def initialize site, installed:
    @site = site
    @installed = installed
  end

  def call
    script_installed if installed? && was_uninstalled?
    script_uninstalled if uninstalled? && was_installed?
  end

  private

  attr_reader :site, :installed

  def installed?
    installed
  end

  def uninstalled?
    !installed?
  end

  def was_installed?
    site.script_installed?
  end

  def was_uninstalled?
    !was_installed?
  end

  def script_installed
    # update_column so that we don't trigger site script regeneration
    site.update_column :script_installed_at, Time.current

    RedeemReferralForRecipient.new(site).call

    track_script_installation
  end

  def script_uninstalled
    # update_column so that we don't trigger site script regeneration
    site.update_column :script_uninstalled_at, Time.current

    track_script_uninstallation
  end

  def track_script_installation
    site.owners.each do |user|
      TrackEvent.new(:installed_script, site: site, user: user).call
    end
  end

  def track_script_uninstallation
    site.owners.each do |user|
      TrackEvent.new(:uninstalled_script, site: site, user: user).call
    end
  end
end
