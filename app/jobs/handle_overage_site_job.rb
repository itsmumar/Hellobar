class HandleOverageSiteJob < ApplicationJob
  def perform(site, number_of_views, limit)
    return unless site
    HandleOverageSite.new(site, number_of_views, limit).call
  end
end
