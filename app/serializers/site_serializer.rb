class SiteSerializer < ActiveModel::Serializer
  include SitesHelper

  attributes :id, :url, :contact_lists, :capabilities, :display_name
  attributes :current_subscription, :script_installed, :num_site_elements
  attributes :view_billing, :timezone
  attributes :monthly_pageviews

  has_many :rules, serializer: RuleSerializer

  def monthly_pageviews
    return unless scope # we require a logged in user

    cache_key = "google:analytics:pageviews:#{ object.id }:#{ scope.id }"
    cache_options = { expires_in: 7.days }

    Rails.cache.fetch(cache_key, cache_options) do
      google = scope.authentications.find { |auth| auth.provider == 'google_oauth2' }

      if google
        analytics = GoogleAnalytics.new(google.access_token)
        analytics.latest_pageviews(object.url)
      end
    end

  rescue Google::Apis::AuthorizationError => error # user has not authenticated with the needed permissions
    return unless scope.is_impersonated
    raise error # the error needs to bubble up to the controller to cause the user to re-authenticate
  end

  def contact_lists
    object.contact_lists.map do |list|
      identity = list.identity_id && Identity.find_by(id: list.identity_id)
      provider_name = identity && identity.provider.titlecase || 'Hello Bar'
      {
        id: list.id,
        name: list.name,
        provider: provider_name
      }
    end
  end

  def capabilities
    {
      remove_branding: object.capabilities.remove_branding?,
      closable: object.capabilities.closable?,
      custom_targeted_bars: object.capabilities.custom_targeted_bars?,
      at_site_element_limit: object.capabilities.at_site_element_limit?,
      custom_thank_you_text: object.capabilities.custom_thank_you_text?,
      after_submit_redirect: object.capabilities.after_submit_redirect?,
      custom_html: object.capabilities.custom_html?,
      content_upgrades: object.capabilities.content_upgrades?,
      autofills: object.capabilities.autofills?,
      geolocation_injection: object.capabilities.geolocation_injection?
    }
  end

  def display_name
    object.normalized_url
  end

  def current_subscription
    if object.current_subscription.present?
      SubscriptionSerializer.new(object.current_subscription)
    else
      {}
    end
  end

  def num_site_elements
    object.site_elements.size
  end

  def view_billing
    scope && Permissions.view_bills?(scope, object)
  end

  def script_installed
    object.script_installed?
  end
end
