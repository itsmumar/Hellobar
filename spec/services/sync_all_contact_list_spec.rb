describe SyncAllContactList do
  let(:contact_list) { create :contact_list, :mailchimp }
  let(:list_id) { contact_list.data['remote_id'] }
  let(:double_optin) { contact_list.double_optin }
  let(:service) { described_class.new(contact_list) }
  let(:contacts) { create_list :data_api_contact, 10 }
  let(:subscribers) { contacts.map { |(email, name, time)| { email: email, name: name, created_at: time } } }

  before { allow(contact_list).to receive(:syncable?).and_return(true) }
  before { allow(Hello::DataAPI).to receive(:contacts).and_return(contacts) }

  context 'when service provider is a EmbedCodeProvider' do
    let(:contact_list) { create :contact_list, :embed_code_form }

    before { allow(contact_list.service_provider).to receive(:action_url).and_return('action_url') }

    it 'sends post request to service_provider.action_url' do
      subscribers.each do |subscriber|
        params = { 'signup[email]' => subscriber[:email], 'signup[name]' => subscriber[:name] }
        expect(HTTParty).to receive(:post).with('action_url', body: params)
      end
      service.call
    end
  end

  context 'when contact list has oauth' do
    before { allow(contact_list).to receive(:oauth?).and_return(true) }

    it 'calls batch_subscribe on identity' do
      expect(contact_list.service_provider).to receive(:batch_subscribe).with(list_id, subscribers, double_optin)
      service.call
    end
  end

  context 'when contact list has api key' do
    before { allow(contact_list).to receive(:api_key?).and_return(true) }

    it 'calls batch_subscribe on identity' do
      expect(contact_list.service_provider).to receive(:batch_subscribe).with(list_id, subscribers, double_optin)
      service.call
    end
  end

  context 'when contact list has a webhook' do
    before { allow(contact_list).to receive(:webhook?).and_return(true) }

    it 'calls batch_subscribe on identity' do
      expect(contact_list.service_provider).to receive(:batch_subscribe).with(list_id, subscribers, double_optin)
      service.call
    end
  end

  context 'with not syncable contact_list' do
    before { allow(contact_list).to receive(:syncable?).and_return(false) }

    it 'does nothing' do
      expect(contact_list.service_provider).not_to receive(:batch_subscribe)
      expect(service.call).to be_nil
    end
  end

  context 'with empty Hello::DataAPI.contacts' do
    before { allow(Hello::DataAPI).to receive(:contacts).and_return([]) }

    it 'does nothing' do
      expect(contact_list.service_provider).not_to receive(:batch_subscribe)
      expect(service.call).to be_empty
    end
  end
end
