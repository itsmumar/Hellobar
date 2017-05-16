class SiteDetectorJob < ApplicationJob
  queue_as { Rails.env.edge? ? 'hellobar_edge' : "hb3_#{ Rails.env }" }

  def perform(site)
    site.update_attribute(:install_type, DetectSiteType.new(site.url).call)
  end
end
