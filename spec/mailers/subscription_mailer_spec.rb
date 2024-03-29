describe SubscriptionMailer do
  describe '.downgrade_to_free' do
    let(:site) { create :site, :pro, :with_user }
    let(:user) { site.users.first }
    let(:previous_subscription) { site.current_subscription }

    subject { SubscriptionMailer.downgrade_to_free(site, user, previous_subscription) }

    it 'set to be delivered to user\'s email' do
      expect(subject).to deliver_to(user.email)
    end

    it 'has correct subject' do
      expect(subject).to have_subject("Your Hello Bar subscription for #{ site.url } has been downgraded to Free")
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
