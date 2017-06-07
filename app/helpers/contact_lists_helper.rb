module ContactListsHelper
  def options_for_provider_select
    providers_array = ServiceProviders::Adapters.enabled.map do |adapter|
      [
        t(adapter.key, scope: :service_providers),
        adapter.key,
        requires_app_url: adapter.config.requires_app_url,
        requires_embed_code: adapter.config.requires_embed_code,
        requires_account_id: adapter.config.requires_account_id,
        requires_api_key: adapter.config.requires_api_key,
        requires_username: adapter.config.requires_username,
        requires_webhook_url: adapter.config.requires_webhook_url,
        oauth: adapter.config.oauth
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
    contact_list.service_provider&.human_name || 'Hello Bar'
  end

  def contact_list_image(contact_list)
    "providers/#{ contact_list_image_key(contact_list) }.png"
  end

  def contact_list_image_key(contact_list)
    contact_list.service_provider ? contact_list.service_provider.name : 'hellobar'
  end
end
