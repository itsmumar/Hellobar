class GoogleAnalytics
  attr_reader :analytics

  def initialize(access_token=nil)
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

  def find_account_by_url(url)
    analytics.list_account_summaries.items.find{|item| item.web_properties.map(&:website_url).include?(url) }
  end

  # what if we don't have an exact url match?
  def get_latest_pageviews(url)
    if account = find_account_by_url(url)
      # what if you have multiple profiles?
      profile = account.web_properties.find{|property| property.website_url == url }.profiles.first
      ids = "ga:#{profile.id}"
      start_date = '30daysAgo'
      end_date = 'today'
      metrics = 'ga:pageviews'

      analytics.get_ga_data(ids, start_date, end_date, metrics).rows.first.first.to_i
    end
  end
end
