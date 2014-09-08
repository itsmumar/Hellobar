module SitesHelper
  def display_url_for_site(site)
    URI.parse(site.url).host
  rescue URI::InvalidURIError
    site.url
  end

  def segment_description(short)
    segment, value = short.split(":", 2)
    user_segment = Hello::Segments::User.find{ |d| d[:key] == segment }
    "#{user_segment[:name]} is #{value}"
  end
end
