describe SubscriptionMailer do
  describe '.downgrade_to_free' do
    let(:site) { create :site, :with_user }
    let(:user) { site.users.first }

    subject { SubscriptionMailer.downgrade_to_free(site, user) }

    it 'set to be delivered to user\'s email' do
      expect(subject).to deliver_to(user.email)
    end

    it 'has correct subject' do
      expect(subject).to have_subject("Your Hello Bar subscription for #{site.url} have been downgraded to Free")
    end

    it 'is sent from hello bar contact email' do
      expect(subject).to deliver_from('Hello Bar <contact@hellobar.com>')
    end

    it 'includes site\'s URL' do
      expect(subject).to have_body_text(site.url)
    end

    it 'includes URL to \'edit site\' page' do
      expect(subject).to have_body_text(edit_site_url(site))
    end
  end
end
