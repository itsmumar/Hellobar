describe SubscribeContact do
  let(:contact_list) { create :contact_list, :mailchimp }
  let(:double_optin) { contact_list.double_optin }
  let(:email) { 'email@contact.com' }
  let(:name) { 'FirstName LastName' }
  let(:contact) { SubscribeContactWorker::Contact.new(contact_list.id, email, name) }
  let(:service) { described_class.new(contact) }
  let(:provider) { double('ServiceProvider') }

  before do
    allow(ServiceProvider).to receive(:new)
      .with(contact_list.identity, contact_list)
      .and_return provider

    allow(contact).to receive(:contact_list).and_return(contact_list)
  end

  context 'when subscription is successful' do
    it 'updates contact status' do
      expect(provider).to receive(:subscribe).with(email: email, name: name)

      expect(UpdateContactStatus).to receive_service_call
        .with(contact_list.id, email, :synced, error: nil)

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
          arguments: { email: email, name: name },
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
end
