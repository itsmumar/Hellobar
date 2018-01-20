class AmplitudeSerializer < ActiveModel::Serializer
  attributes :user_id, :first_name, :last_name, :email, :primary_domain

  def user_id
    object.id
  end

  def primary_domain
    NormalizeURI[object.sites.first&.url]&.domain
  end
end
