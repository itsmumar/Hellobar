class ResetCurrentOverageJob < ApplicationJob
  queue_as { "hb3_#{ Rails.env }" }

  def perform(site)
    return unless site
    views = FetchTotalViewsForMonth.new([site]).call
    number_of_views = views.fetch(site.id, 0)
    limit = site.views_limit
    HandleOverageSite.new(site, number_of_views, limit).call if number_of_views >= limit
  end
end
