describe SubscribeAllContacts do
  let(:contact_list) { create :contact_list, :mailchimp }
  let(:contacts) { create_list :data_api_contact, 10 }
  let(:service) { described_class.new(contact_list) }
  let(:provider) { double('ServiceProviders::Provider') }

  before { allow(Hello::DataAPI).to receive(:contacts).and_return(contacts) }
  before do
    allow(ServiceProviders::Provider).to receive(:new).with(contact_list.identity, contact_list).and_return(provider)
  end

  describe '#call' do
    context 'with syncable contact_list' do
      let(:subscribers) { contacts.map { |(email, name)| { email: email, name: name } } }

      before { allow(contact_list).to receive(:syncable?).and_return(true) }

      it 'calls #batch_subscribe on provider' do
        expect(provider).to receive(:batch_subscribe).with(contact_list.data['remote_id'], subscribers)
        service.call
      end
    end

    context 'with not syncable contact_list' do
      before { allow(contact_list).to receive(:syncable?).and_return(false) }

      it 'does nothing' do
        expect(provider).not_to receive(:batch_subscribe)
        service.call
      end
    end
  end
end
