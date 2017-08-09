describe ContactsMailer do
  describe 'csv_export' do
    let(:user) { create :user }
    let(:contact_list) { create :contact_list }
    let(:mail) { ContactsMailer.csv_export user, contact_list }
    let(:attachment) { mail.attachments[0] }

    let(:subject) do
      url = contact_list.site.normalized_url
      "#{ url }: Your CSV export is ready #{ contact_list.name.parameterize }.zip"
    end

    before do
      expect(FetchContactsCSV)
        .to receive_service_call.with(contact_list).and_return('csv')
    end

    it 'renders the headers' do
      expect(mail.subject).to eq subject
      expect(mail.to).to eq [user.email]
      expect(mail.from).to eq ['contact@hellobar.com']
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match('Your CSV export is ready')
      expect(mail.body.encoded).to match('All your contacts were exported to csv.')
    end

    it 'attaches zipped csv' do
      expect(attachment.filename).to eql "#{ contact_list.name.parameterize }.zip"
    end
  end
end
