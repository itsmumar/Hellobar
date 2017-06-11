module ContactListFeatureHelper
  def open_provider_form(user, pname)
    visit site_contact_lists_path(site)

    page.find('#new-contact-list').click
    page.find('span', text: 'View all tools').click
    page.find(".#{ pname }-provider").click
  end

  def connect_to_provider(user, provider)
    open_provider_form(user, provider)
    yield if block_given?
    page.find('.button.ready').click
  end
end

class TestProvider < ServiceProvider::Adapters::Base
  def initialize(identity)
  end

  def tags
    [{ 'id' => 'tag1', 'name' => 'Tag 1' }]
  end

  def lists
    [{ 'id' => 'list1', 'name' => 'List 1' }]
  end

  def subscribe(email:, name:)
  end
end

RSpec.configure do |config|
  config.before contact_list_feature: true do
    stub_out_ab_variations('Upgrade Pop-up for Active Users 2016-08') { 'variant' }
    allow(Settings).to receive(:fake_data_api).and_return true
    allow(ServiceProvider).to receive(:adapter).and_wrap_original do |original_method, key|
      original_provider = original_method.call(key)
      TestProvider.config = original_provider.config
      TestProvider
    end
  end
end
