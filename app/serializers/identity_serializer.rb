class IdentitySerializer < ActiveModel::Serializer
  attributes :id, :site_id, :provider, :lists

  def lists
    object.service_provider.lists.map{|l| {:name => l["name"], :id => l["id"]}}
  end
end
