module ContactListsHelper
  def options_for_provider_select
    providers = Hellobar::Settings[:identity_providers].select{|k, v| v[:type] == :email}
    [["In Hello Bar only", 0]] + providers.map {|k, v| [v[:name], k, requires_embed_code: !!v[:requires_embed_code]] }
  end

  def contact_list_sync_details(contact_list)
    if contact_list.data["remote_name"] && !contact_list.data["remote_name"].blank?
      "Syncing contacts with #{contact_list.service_provider.name} list \"#{contact_list.data["remote_name"]}\""
    elsif contact_list.identity
      "Syncing contacts with #{contact_list.service_provider.name}"
    else
      "Storing contacts in Hello Bar only"
    end
  end

  def contact_list_provider_name(contact_list)
    contact_list.service_provider.try(:name) || "Hello Bar"
  end

  def contact_list_image(contact_list)
    "providers/#{contact_list_image_key(contact_list)}.png"
  end

  def contact_list_image_key(contact_list)
    contact_list.service_provider ? contact_list.service_provider.key : "hellobar"
  end
end
