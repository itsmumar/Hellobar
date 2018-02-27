class SiteSerializer < ActiveModel::Serializer
  include SitesHelper

  attributes :id, :url, :contact_lists, :capabilities, :display_name
  attributes :current_subscription, :script_installed, :site_elements_count
  attributes :view_billing, :timezone

  has_many :rules, serializer: RuleSerializer

  def contact_lists
    object.contact_lists.map do |list|
      list_attributes = {
        id: list.id,
        name: list.name,
        provider_name: list.provider_name
      }

      subscribers_count = list_subscribers_count(list.id)
      list_attributes[:subscribers_count] = subscribers_count if subscribers_count

      list_attributes
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
      content_upgrades: object.capabilities.content_upgrades?,
      autofills: object.capabilities.autofills?,
      geolocation_injection: object.capabilities.geolocation_injection?,
      precise_geolocation_targeting: object.capabilities.precise_geolocation_targeting?,
      external_tracking: object.capabilities.external_tracking?,
      alert_bars: object.capabilities.alert_bars?,
      opacity: object.capabilities.opacity?
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

  def site_elements_count
    object.site_elements.size
  end

  def view_billing
    scope && Permissions.view_bills?(scope, object)
  end

  def script_installed
    object.script_installed?
  end

  private

  def list_subscribers_count(list_id)
    context && context[:list_totals] && context[:list_totals][list_id]
  end
end
