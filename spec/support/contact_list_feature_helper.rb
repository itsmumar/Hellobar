module ContactListFeatureHelper
  def open_provider_form(site, provider)
    ContactListsPage.visit(site).new_contact_list.tap do |modal|
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

  def stub_provider(provider)
    allow(ServiceProvider::Adapters.fetch(provider))
      .to receive(:new).and_wrap_original { |identity| TestProvider.new(identity) }
  end
end
