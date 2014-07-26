module ContactListsHelper
  def options_for_provider_select
    providers = Hellobar::Settings[:identity_providers].values.select{|v| v[:type] == :email && !v[:requires_embed_code]}
    [["In Hello Bar only", 0]] + providers.map{|v| [v[:name], v[:key]]}
  end
end
