describe FetchContactsCSV, :freeze do
  let(:contact_list) { create :contact_list }
  let(:service) { FetchContactsCSV.new(contact_list) }
  let(:contacts) { [email: 'email@example.com', name: 'name', subscribed_at: Time.current] }

  describe '#call' do
    before do
      expect(FetchContacts)
        .to receive_service_call
        .with(contact_list, limit: nil)
        .and_return contacts
    end

    let(:header) { 'Email,Fields,Subscribed At' }
    let(:content) { "email@example.com,name,#{ Time.current }" }

    it 'returns contacts as csv' do
      expect(service.call).to eql "#{ header }\n#{ content }\n"
    end
  end
end
