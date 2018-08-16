describe External::SubscriberSerializer do
  let(:contact) { Contact.new(email: 'email@example.com', name: 'Name') }
  let(:contact_list) { 'Contact List' }

  let(:serializer) do
    External::SubscriberSerializer.new(contact, scope: { contact_list: contact_list })
  end

  describe(:serializable_hash) do
    subject(:json) { serializer.serializable_hash }

    it 'includes name' do
      expect(json[:name]).to eq(contact.name)
    end

    it 'includes email' do
      expect(json[:email]).to eq(contact.email)
    end

    it 'includes contact_list' do
      expect(json[:contact_list]).to eq(contact_list)
    end
  end
end
