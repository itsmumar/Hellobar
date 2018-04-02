class CurrentUserSerializer < UserSerializer
  attributes :email, :sites, :site_id, :token

  def sites
    object.sites.map do |site|
      SiteSerializer.new(site, scope: scope)
    end
  end

  def site_id
    scope && scope[:site_id]
  end

  def token
    scope && scope[:token]
  end
end
