class SendEmailDigestJob < ApplicationJob
  def perform(site)
    return unless any_views_within_last_week?(site)
    SendEmailDigest.new(site).call
  end

  private

  def any_views_within_last_week?(site)
    site_statistics = FetchSiteStatistics.new(site, days_limit: 14).call
    site_statistics.within(EmailDigestHelper.last_week).views?
  end
end
