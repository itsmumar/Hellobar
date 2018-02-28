class CurrentUserSerializer < UserSerializer
  attributes :email, :sites, :site_id, :token

  def sites
    object.sites.map do |site|
      SiteSerializer.new(site, context: context)
    end
  end

  def site_id
    context && context[:site_id]
  end

  def token
    context && context[:token]
  end
end
