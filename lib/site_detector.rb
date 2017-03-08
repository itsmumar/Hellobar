class SiteDetector
  attr_reader :url
  # Spoof the user agent because many sites (like square space ones) send a
  # 403 forbidden when using the httparty default user agent
  USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.130 Safari/537.36'

  def initialize(url)
    @url = url
  end

  def site_type
    @response ||= HTTParty.get(url, timeout: 10, headers: { 'User-Agent' => USER_AGENT })
    case @response
    when /static.squarespace.com/
      :squarespace
    when /cdn.shopify.com/
      :shopify
    when /weebly.com/
      :weebly
    when /wp-content/
      :wordpress
    when /https:\/\/www.blogger.com/
      :blogspot
    end
  rescue
    nil # Couldn't connect to their site, so assume nil
  end
end
