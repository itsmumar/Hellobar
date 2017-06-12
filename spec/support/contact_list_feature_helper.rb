module ContactListFeatureHelper
  def open_provider_form(site, provider)
    visit site_contact_lists_path(site)

    page.find('#new-contact-list').click
    page.find('span', text: 'View all tools').click
    page.find(".#{ provider }-provider").click
  end

  def connect_to_provider(site, provider)
    open_provider_form(site, provider)
    yield if block_given?
    page.find('.button.ready').click
  end
end
