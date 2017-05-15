class SiteDetectorJob < ApplicationJob
  queue_as Settings.main_queue

  def perform(site)
    site.update_attribute(:install_type, DetectSiteType.new(site.url).call)
  end
end
