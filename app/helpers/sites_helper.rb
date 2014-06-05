module SitesHelper
  def display_url_for_site(site)
    URI.parse(site.url).host
  rescue URI::InvalidURIError
    site.url
  end
end
