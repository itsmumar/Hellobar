describe ExportSubscribers, :freeze do
  let(:contact_list) { create :contact_list }
  let(:service) { described_class.new(contact_list) }
  let(:subscribers) { [Contact.new(email: 'email@example.com', name: 'name', subscribed_at: Time.current)] }

  describe '#call' do
    before do
      expect(FetchSubscribers)
        .to receive_service_call
        .with(contact_list)
        .and_return(items: subscribers)
    end

    let(:header) { 'Email,Fields,Subscribed At' }
    let(:content) { "email@example.com,name,#{ Time.current }" }

    it 'returns subscribers as csv' do
      expect(service.call).to eql "#{ header }\n#{ content }\n"
    end
  end
end
