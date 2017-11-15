class AmplitudeSerializer < ActiveModel::Serializer
  attributes :user_id, :first_name, :last_name, :email, :primary_domain, :additional_domains,
    :contact_lists, :total_views, :total_conversions

  def user_id
    object.id
  end

  def primary_domain
    NormalizeURI[object.sites.first&.url]&.domain
  end

  def additional_domains
    object.sites.map { |site| NormalizeURI[site.url]&.domain }.compact.join(', ')
  end

  def contact_lists
    object.contact_lists.count
  end

  def total_views
    object.sites.map { |site| site.statistics.views }.sum
  end

  def total_conversions
    object.sites.map { |site| site.statistics.conversions }.sum
  end
end
