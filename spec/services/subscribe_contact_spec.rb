describe SubscribeContact do
  let(:contact_list) { create :contact_list, :mailchimp }
  let(:double_optin) { contact_list.double_optin }
  let(:email) { 'email@contact.com' }
  let(:name) { 'firstname lastname' }
  let(:contact) { SubscribeContactWorker::Contact.new(contact_list.id, email, name) }
  let(:service) { described_class.new(contact) }
  let(:provider) { double('ServiceProvider') }
  let(:last_log_entry) { contact_list.contact_list_logs.last }

  before do
    allow(ServiceProvider).to receive(:new)
      .with(contact_list.identity, contact_list)
      .and_return provider

    allow(contact).to receive(:contact_list).and_return(contact_list)
  end

  before { allow(contact).to receive(:contact_list).and_return(contact_list) }
  before { allow(provider).to receive(:subscribe).with(email: email, name: name.titleize) }

  context 'when subscription is successful' do
    before do
      expect(provider).to receive(:subscribe).with(email: email, name: name.titleize)

      expect(UpdateContactStatus).to receive_service_call
        .with(contact_list.id, email, :synced, error: nil)
    end

    it 'creates contact list logs' do
      expect { service.call }.to change(contact_list.contact_list_logs, :count).to(1)
    end

    it 'marks contact list log as completed' do
      service.call
      expect(last_log_entry).to be_completed
    end
  end

  context 'when error is raised' do
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

    before do
      expect(UpdateContactStatus).to receive_service_call
        .with(contact_list.id, email, :error, error: exception.to_s)
    end

    it 'does not mark contact list log as completed and raises error' do
      service.call
      expect(last_log_entry).not_to be_completed
    end

    it 'calls Raven.capture_exception' do
      expect(Raven).to receive(:capture_exception).with(instance_of(exception), options)
      service.call
    end
  end

  context 'when ServiceProvider::InvalidSubscriberError exception is raised' do
    let(:exception) { ServiceProvider::InvalidSubscriberError }

    before do
      expect(provider).to receive(:subscribe).and_raise exception
      expect(UpdateContactStatus).to receive_service_call
        .with(contact_list.id, email, :error, error: exception.to_s)
    end

    it 'does not mark contact list log as completed' do
      service.call

      expect(last_log_entry).not_to be_completed
    end
  end
end
