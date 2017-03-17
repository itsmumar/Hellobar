module ContactListsHelper
  def options_for_provider_select
    providers = Hellobar::Settings[:identity_providers].select { |_, v| v[:hidden] != true }
    providers_array = providers.map do |provider_name, provider_attributes|
      [
        provider_attributes[:name],
        provider_name,
        requires_app_url:     !provider_attributes[:requires_app_url].nil?,
        requires_embed_code:  !provider_attributes[:requires_embed_code].nil?,
        requires_account_id:  !provider_attributes[:requires_account_id].nil?,
        requires_api_key:     !provider_attributes[:requires_api_key].nil?,
        requires_username:    !provider_attributes[:requires_username].nil?,
        requires_webhook_url: !provider_attributes[:requires_webhook_url].nil?,
        oauth:                !provider_attributes[:oauth].nil?
      ]
    end

    [['In Hello Bar only', 0]] + providers_array
  end

  # rubocop: disable Rails/OutputSafety
  def contact_list_sync_details(contact_list)
    if contact_list.data['remote_name'].present? && contact_list.service_provider.present?
      "<small>Syncing contacts with</small><span>#{ contact_list.service_provider.name } list \"#{ contact_list.data['remote_name'] }\"</span>".html_safe
    elsif contact_list.service_provider.present?
      "<small>Syncing contacts with</small><span>#{ contact_list.service_provider.name }</span>".html_safe
    else
      '<small>Storing contacts in</small><span>Hello Bar</span>'.html_safe
    end
  end
  # rubocop: enable Rails/OutputSafety

  def contact_list_provider_name(contact_list)
    contact_list.service_provider.try(:name) || 'Hello Bar'
  end

  def contact_list_image(contact_list)
    "providers/#{ contact_list_image_key(contact_list) }.png"
  end

  def contact_list_image_key(contact_list)
    contact_list.service_provider ? contact_list.service_provider.key : 'hellobar'
  end
end
