module ExternalUrlsHelper
  TERMS_OF_USE_PATH = '/terms-of-use'.freeze
  PRIVACY_POLICY_PATH = '/privacy-policy'.freeze

  def terms_of_use_url
    URI.join(Settings.marketing_site_url, TERMS_OF_USE_PATH).to_s
  end

  def privacy_policy_url
    URI.join(Settings.marketing_site_url, PRIVACY_POLICY_PATH).to_s
  end
end
