describe SubscribeContact do
  let(:contact_list) { create :contact_list, :mailchimp }
  let(:double_optin) { contact_list.double_optin }
  let(:email) { 'email@contact.com' }
  let(:name) { 'FirstName LastName' }
  let(:contact) { SubscribeContactWorker::Contact.new(contact_list.id, email, name) }
  let(:service) { described_class.new(contact) }
  let(:provider) { double('ServiceProviders::Provider') }
  let(:last_log_entry) { contact_list.contact_list_logs.last }

  before do
    allow(ServiceProviders::Provider).to receive(:new).with(contact_list.identity, contact_list).and_return(provider)
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

    it 'does not mark contact list log as completed and raises error' do
      expect { service.call }.to raise_error StandardError
      expect(last_log_entry).not_to be_completed
    end
  end
end
