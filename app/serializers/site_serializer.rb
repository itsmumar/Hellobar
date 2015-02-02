class SiteSerializer < ActiveModel::Serializer
  include SitesHelper

  attributes :id, :url, :contact_lists, :capabilities, :display_name
  attributes :current_subscription, :has_script_installed?, :num_site_elements

  has_many :rules, serializer: RuleSerializer

  def contact_lists
    object.contact_lists.map do |list|
      {
        :id => list.id,
        :name => list.name
      }
    end
  end

  def capabilities
    {
      :remove_branding => object.capabilities.remove_branding?,
      :custom_targeted_bars => object.capabilities.custom_targeted_bars?,
      :at_site_element_limit => object.capabilities.at_site_element_limit?,
      :custom_thank_you_text => object.capabilities.custom_thank_you_text?
    }
  end

  def display_name
    display_name_for_site(object)
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
end
