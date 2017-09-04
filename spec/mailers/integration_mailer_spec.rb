describe IntegrationMailer do
  describe '#sync_error' do
    let(:user) { create :user }
    let(:site) { create :site }
    let(:identity) { create :identity, site: site }
    let(:mail) { IntegrationMailer.sync_error user, identity }

    let(:subject) { "There was a problem syncing your #{ identity.provider_name } account" }

    it 'renders the headers' do
      expect(mail.subject).to eq subject
      expect(mail.to).to eq [user.email]
      expect(mail.from).to eq ['support@hellobar.com']
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match(identity.provider_name)
      expect(mail.body.encoded).to match(site_contact_lists_url(site))
    end
  end
end
