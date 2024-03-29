module ContactListsHelper
  DELETED = 'DELETED'.freeze

  def options_for_provider_select
    providers_array = ServiceProvider::Adapters.enabled.map do |adapter|
      [
        t(adapter.key, scope: :service_providers),
        adapter.key,
        requires_app_url: adapter.config.requires_app_url,
        requires_embed_code: adapter.config.requires_embed_code,
        requires_account_id: adapter.config.requires_account_id,
        requires_api_key: adapter.config.requires_api_key,
        requires_username: adapter.config.requires_username,
        requires_webhook_url: adapter.config.requires_webhook_url,
        hidden: adapter.config.hidden,
        oauth: adapter.config.oauth
      ]
    end

    [['In Hello Bar only', 0]] + providers_array
  end

  def contact_list_title(contact_list)
    title = "#{ contact_list.name } (id: #{ contact_list.id })"
    title << " - #{ DELETED }" if contact_list.deleted?
    title
  end

  def contact_list_sync_details(contact_list)
    if contact_list.data['remote_name'].present?
      "<small>Syncing contacts with</small><span>#{ contact_list.provider_name } list \"#{ contact_list.data['remote_name'] }\"</span>"
    elsif contact_list.identity_id.present?
      "<small>Syncing contacts with</small><span>#{ contact_list.provider_name }</span>"
    else
      '<small>Storing contacts in</small><span>Hello Bar</span>'
    end
  end

  def contact_status(contact)
    if contact.synced?
      'Sent'
    elsif contact.unsynced?
      'Unsynced'
    elsif contact.error?
      content_tag :abbr, 'Error', title: contact.error
    end
  end
end
