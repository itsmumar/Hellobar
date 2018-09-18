class SiteSerializer < ActiveModel::Serializer
  include SitesHelper

  attributes :id, :url, :contact_lists, :capabilities, :display_name
  attributes :current_subscription, :script_installed, :site_elements_count
  attributes :view_billing, :timezone, :rules
  attributes :gdpr_enabled

  def contact_lists
    object.contact_lists.map do |list|
      list_attributes = {
        id: list.id,
        name: list.name,
        provider_name: list.provider_name,
        icon_path: list.provider_icon_path
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
      leading_question: object.capabilities.leading_question?,
      image_opacity: object.capabilities.image_opacity?,
      image_overlay_opacity: object.capabilities.image_overlay_opacity?,
      a_b_test_in_progress: object.capabilities.a_b_test_in_progress?,
      max_variations: object.capabilities.max_variations
    }
  end

  def display_name
    object.host
  end

  def current_subscription
    if object.current_subscription.present?
      SubscriptionSerializer.new(object.current_subscription).as_json
    else
      {}
    end
  end

  def site_elements_count
    object.site_elements.size
  end

  def view_billing
    scope && scope[:user] && Permissions.view_bills?(scope[:user], object)
  end

  def script_installed
    object.script_installed?
  end

  def rules
    object.rules.map { |rule| RuleSerializer.new(rule).as_json }
  end

  def gdpr_enabled
    object.gdpr_enabled?
  end

  private

  def list_subscribers_count(list_id)
    scope && scope[:list_totals] && scope[:list_totals][list_id]
  end
end
