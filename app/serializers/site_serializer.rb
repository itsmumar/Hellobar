class SiteSerializer < ActiveModel::Serializer
  include SitesHelper

  attributes :id, :url, :contact_lists, :capabilities, :display_name
  attributes :current_subscription, :script_installed, :num_site_elements
  attributes :view_billing, :timezone

  has_many :rules, serializer: RuleSerializer

  def contact_lists
    object.contact_lists.map do |list|
      {
        id: list.id,
        name: list.name,
        provider_name: list.provider_name
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
      geolocation_injection: object.capabilities.geolocation_injection?,
      external_tracking: object.capabilities.external_tracking?,
      alert_bars: object.capabilities.alert_bars?
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
