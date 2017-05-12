class SiteDetectorJob < ApplicationJob
  queue_as { Settings.main_queue }

  def perform(site)
    return if Rails.env.test?

    site.update_attribute(:install_type, SiteDetector.new(site.url).site_type)
  end
end
