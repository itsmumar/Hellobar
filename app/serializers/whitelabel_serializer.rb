class WhitelabelSerializer < ActiveModel::Serializer
  attributes :id, :domain, :subdomain, :status, :site_id, :domain_identifier, :dns
end
