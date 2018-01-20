class WhitelabelSerializer < ActiveModel::Serializer
  attributes :id, :domain, :subdomain, :status, :site_id
end
