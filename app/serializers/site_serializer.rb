class SiteSerializer < ActiveModel::Serializer
  include SitesHelper

  attributes :id, :url, :contact_lists, :capabilities, :display_name

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
      :at_site_element_limit => object.capabilities.at_site_element_limit?
    }
  end

  def display_name
    display_name_for_site(object)
  end
end
