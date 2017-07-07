describe SubscribeContact do
  let(:contact_list) { create :contact_list, :mailchimp }
  let(:double_optin) { contact_list.double_optin }
  let(:email) { 'email@contact.com' }
  let(:name) { 'FirstName LastName' }
  let(:contact) { SubscribeContactWorker::Contact.new(contact_list.id, email, name) }
  let(:service) { described_class.new(contact) }
  let(:provider) { double('ServiceProvider') }
  let(:last_log_entry) { contact_list.contact_list_logs.last }

  before do
    allow(ServiceProvider).to receive(:new).with(contact_list.identity, contact_list).and_return(provider)
  end

  before { allow(contact).to receive(:contact_list).and_return(contact_list) }
  before { allow(provider).to receive(:subscribe).with(email: email, name: name) }

  it 'creates contact list logs' do
    expect { service.call }.to change(contact_list.contact_list_logs, :count).to(1)
  end

  it 'marks contact list log as completed' do
    service.call
    expect(last_log_entry).to be_completed
  end

  context 'when error is raised' do
    before { allow(provider).to receive(:subscribe).and_raise StandardError }
    before { allow(Rails.env).to receive(:test?).and_return(false) }
    before { allow(provider).to receive(:adapter).and_return(TestProvider.new(nil)) }

    let(:options) do
      {
        extra: {
          identity_id: contact_list.identity.id,
          contact_list_id: contact_list.id,
          remote_list_id: contact_list.data['remote_id'],
          arguments: { email: email, name: name },
          double_optin: contact_list.double_optin,
          tags: contact_list.tags,
          exception: '#<StandardError: StandardError>'
        },
        tags: { type: 'service_provider', adapter_key: nil, adapter_class: 'TestProvider' }
      }
    end

    it 'does not mark contact list log as completed and raises error' do
      service.call
      expect(last_log_entry).not_to be_completed
    end

    it 'calls Raven.capture_exception' do
      expect(Raven).to receive(:capture_exception).with(instance_of(StandardError), options)
      service.call
      # expect { service.call }.not_to raise_error
    end
  end

  context 'when ServiceProvider::InvalidSubscriberError is raised' do
    before { allow(provider).to receive(:subscribe).and_raise ServiceProvider::InvalidSubscriberError }

    it 'does not mark contact list log as completed' do
      service.call
      expect(last_log_entry).not_to be_completed
    end
  end
end
