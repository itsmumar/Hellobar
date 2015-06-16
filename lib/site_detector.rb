class SiteDetector
  attr_reader :url

  def initialize(url)
    @url = url
  end

  def site_type
    @response ||= HTTParty.get(url, timeout: 10)
    case @response
    when /weebly.com/
      :weebly
    when /wp-content/
      :wordpress
    else
      nil
    end
  end
end
