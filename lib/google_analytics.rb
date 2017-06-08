class GoogleAnalytics
  attr_reader :analytics

  def initialize(access_token = nil, expires_at = 1.hour.from_now)
    authorization = Signet::OAuth2::Client.new(
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      token_credential_uri: 'https://www.googleapis.com/oauth2/v4/token',
      client_id: Settings.google_auth_id,
      client_secret: Settings.google_auth_secret,
      scope: 'email profile https://www.googleapis.com/auth/analytics.readonly',
      access_token: access_token
    )

    # Fix signet issue (https://github.com/google/signet/issues/75#issuecomment-231954956)
    authorization.expires_at = expires_at

    @analytics = Google::Apis::AnalyticsV3::AnalyticsService.new
    @analytics.authorization = authorization
  end

  def self.normalize_url(url)
    normalized_url = Site.normalize_url(url)

    "#{ normalized_url.scheme }://#{ normalized_url.normalized_host }"
  end

  def find_account_by_url(url)
    analytics.list_account_summaries.items.find do |item|
      web_properties = item.web_properties
      next if web_properties.blank?
      urls = web_properties.map(&:website_url).compact.map { |web_url| self.class.normalize_url(web_url) }

      urls.include?(self.class.normalize_url(url))
    end
  rescue Google::Apis::TransmissionError => error
    Raven.capture_exception(error)
    return
  rescue Google::Apis::ClientError => error
    return if error.to_s =~ /insufficientPermissions/
    raise error
  rescue ActionView::Template::Error => _
    nil # handle for timeouts
  rescue => e
    Rails.logger.warn e.inspect
    Rails.logger.warn e.message
    raise e
  end

  # what if we don't have an exact url match?
  def latest_pageviews(url)
    account = find_account_by_url(url)
    return unless account

    # what if you have multiple profiles?
    profile = account.web_properties.find { |property|
      next if property.website_url.blank?

      self.class.normalize_url(property.website_url) == self.class.normalize_url(url)
    }.profiles.first

    ids = "ga:#{ profile.id }"
    start_date = '30daysAgo'
    end_date = 'today'
    metrics = 'ga:pageviews'

    analytics.get_ga_data(ids, start_date, end_date, metrics).rows.try(:first).try(:first).to_i
  end
end
