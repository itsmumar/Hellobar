describe SubscribeContact do
  # 1.minute.ago is required to test cache invalidation
  let(:contact_list) { create(:contact_list, :mailchimp, updated_at: 1.minute.ago) }
  let(:site_element) { create(:site_element, :email, contact_list: contact_list, updated_at: 1.minute.ago) }
  let(:double_optin) { contact_list.double_optin }
  let(:email) { 'email@contact.com' }
  let(:name) { 'Firstname Lastname' }
  let(:contact) { SubscribeContactWorker::Contact.new(contact_list.id, email, name) }
  let(:service) { described_class.new(contact) }
  let(:provider) { double('ServiceProvider') }

  before do
    allow(ServiceProvider).to receive(:new)
      .with(contact_list.identity, contact_list)
      .and_return provider

    allow(provider).to receive(:subscribe)
    allow(contact).to receive(:contact_list).and_return(contact_list)

    allow(UpdateContactStatus).to receive_service_call
    allow(ExecuteSequenceTriggers).to receive_service_call
  end

  before { allow(contact).to receive(:contact_list).and_return(contact_list) }
  before { allow(provider).to receive(:subscribe).with(email: email, name: name.titleize) }

  context 'when subscription is successful' do
    it 'calls subscribe on provider instance' do
      expect(provider).to receive(:subscribe).with(email: email, name: name)

      service.call
    end

    it 'updates contact status' do
      expect(UpdateContactStatus).to receive_service_call
        .with(contact_list.id, email, :synced, error: nil)

      service.call
    end

    it 'updates contact_list.cache_key' do
      expect { service.call }.to change { contact_list.cache_key }
    end

    it 'updates site_element.cache_key' do
      expect { service.call }.to change { site_element.reload.cache_key }
    end

    it 'executes email sequence triggers' do
      expect(ExecuteSequenceTriggers).to receive_service_call.with(email, name, contact_list)

      service.call
    end
  end

  context 'when StandardError exception is raised' do
    let(:exception) { StandardError }
    let(:options) do
      {
        extra: {
          identity_id: contact_list.identity.id,
          contact_list_id: contact_list.id,
          remote_list_id: contact_list.data['remote_id'],
          arguments: { email: email, name: name.titleize },
          double_optin: contact_list.double_optin,
          tags: contact_list.tags,
          exception: '#<StandardError: StandardError>'
        },
        tags: {
          type: 'service_provider',
          adapter_key: nil,
          adapter_class: 'TestProvider'
        }
      }
    end

    before { allow(provider).to receive(:subscribe).and_raise exception }
    before { allow(Rails.env).to receive(:test?).and_return(false) }
    before { allow(provider).to receive(:adapter).and_return(TestProvider.new(nil)) }

    it 'sets contact status to :error and raises the exception' do
      expect(UpdateContactStatus).to receive_service_call
        .with(contact_list.id, email, :error, error: exception.to_s)

      expect(Raven).to receive(:capture_exception).with(instance_of(exception), options)

      service.call
    end
  end

  context 'when ServiceProvider::InvalidSubscriberError exception is raised' do
    let(:exception) { ServiceProvider::InvalidSubscriberError }

    it 'sets contact status to :error and raises the exception' do
      expect(provider).to receive(:subscribe).and_raise exception
      expect(UpdateContactStatus).to receive_service_call
        .with(contact_list.id, email, :error, error: exception.to_s)

      service.call
    end
  end

  context 'when contact list has been deleted' do
    before { contact_list.destroy }

    it 'does not raise error' do
      expect { service.call }.not_to raise_error
    end
  end
end
