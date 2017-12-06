class Url2png
  def initialize(url:, viewport: nil, include_protocol: false)
    @options = { viewport: viewport, url: url }
    @protocol = include_protocol ? 'https://' : ''
  end

  def call
    "#{ protocol }api.url2png.com/v6/#{ apikey }/#{ token }/png/?#{ query_string }"
  end

  private

  attr_reader :query_string, :options, :protocol

  def token
    Digest::MD5.hexdigest(query_string + secret)
  end

  def css_url
    "http://#{ Settings.host }/stylesheets/hide_bar.css"
  end

  def query_string
    options.reverse_merge(custom_css_url: css_url, ttl: 7.days.to_i)
      .compact
      .sort
      .map { |k, v| "#{ CGI::escape(k.to_s) }=#{ CGI::escape(v.to_s) }" }
      .join('&')
  end

  def apikey
    Settings.url2png_api_key
  end

  def secret
    Settings.url2png_api_secret
  end
end
