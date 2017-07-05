module ContactListFeatureHelper
  def open_provider_form(site, provider)
    ContactListsPage.visit(site).new_list_modal.tap do |modal|
      modal.view_all_tools
      modal.choose_provider(provider)
    end
  end

  def connect_to_provider(site, provider)
    open_provider_form(site, provider).tap do |modal|
      yield modal if block_given?
      modal.connect
    end
  end
end
