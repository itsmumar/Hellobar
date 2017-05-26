class SiteDetectorJob < ApplicationJob
  def perform(site)
    site.update_attribute(:install_type, DetectSiteType.new(site.url).call)
  end
end
