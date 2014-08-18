module ContactListsHelper
  def options_for_provider_select
    providers = Hellobar::Settings[:identity_providers].select{|k, v| v[:type] == :email}
    [["In Hello Bar only", 0]] + providers.map {|k, v| [v[:name], k, requires_embed_code: !!v[:requires_embed_code]] }
  end

  def contact_list_sync_details(contact_list)
    if contact_list.identity && contact_list.data["remote_name"]
      provider = Hellobar::Settings[:identity_providers][contact_list.identity.provider.to_sym][:name]
      "Syncing contacts with #{provider} list \"#{contact_list.data["remote_name"]}\""
    else
      "Storing contacts in Hello Bar only"
    end
  end
end
