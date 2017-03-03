class GoogleAnalytics
  attr_reader :analytics

  def initialize(access_token = nil)
    client = Signet::OAuth2::Client.new(
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      token_credential_uri: 'https://www.googleapis.com/oauth2/v3/token',
      client_id: Hellobar::Settings[:google_auth_id],
      client_secret: Hellobar::Settings[:google_auth_secret],
      scope: 'email profile https://www.googleapis.com/auth/analytics.readonly',
      access_token: access_token
    )

    @analytics = Google::Apis::AnalyticsV3::AnalyticsService.new
    @analytics.authorization = client
  end

  def self.normalize_url(url)
    normalized_url = Site.normalize_url(url)

    "#{normalized_url.scheme}://#{normalized_url.normalized_host}"
  end

  def find_account_by_url(url)
    analytics.list_account_summaries.items.find do |item|
      web_properties = item.web_properties
      next if web_properties.blank?
      urls = web_properties.map(&:website_url).compact.map { |web_url| self.class.normalize_url(web_url) }

      urls.include?(self.class.normalize_url(url))
    end
  rescue Google::Apis::ClientError => error
    if error.to_s.match(/insufficientPermissions/)
      nil # handle for when a user doesn't have a Google Analytics account
    else
      raise error
    end
  rescue ActionView::Template::Error => error
    nil # handle for timeouts
  rescue => e
    Rails.logger.warn e.inspect
    Rails.logger.warn e.message
    raise e
  end

  # what if we don't have an exact url match?
  def get_latest_pageviews(url)
    account = find_account_by_url(url)

    if account
      # what if you have multiple profiles?
      profile = account.web_properties.find do |property|
        next unless property.website_url.present?

        self.class.normalize_url(property.website_url) == self.class.normalize_url(url)
      end.profiles.first

      ids = "ga:#{profile.id}"
      start_date = '30daysAgo'
      end_date = 'today'
      metrics = 'ga:pageviews'

      analytics.get_ga_data(ids, start_date, end_date, metrics).rows.try(:first).try(:first).to_i
    end
  end
end
