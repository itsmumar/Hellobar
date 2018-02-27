class CurrentUserSerializer < UserSerializer
  attributes :email, :sites

  def sites
    object.sites.map do |site|
      SiteSerializer.new(site, context: context)
    end
  end
end
