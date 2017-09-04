describe TeamMailer do
  describe '#invite' do
    let(:site_membership) { create :site_membership }
    let(:user) { site_membership.user }
    let(:site) { site_membership.site }
    let(:mail) { TeamMailer.invite site_membership }

    let(:subject) { 'You\'ve been added to a Hello Bar team.' }

    it 'renders the headers' do
      expect(mail.subject).to eq subject
      expect(mail.to).to eq [user.email]
      expect(mail.from).to eq ['contact@hellobar.com']
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include new_user_session_url
      expect(mail.body.encoded).to include site.normalized_url
    end

    context 'when user is an oauth user' do
      before { allow(user).to receive(:oauth_user?).and_return true }

      it 'includes oauth url' do
        expect(mail.body.encoded).to include oauth_login_url(action: 'google_oauth2')
        expect(mail.body.encoded).not_to include new_user_session_url
      end
    end

    context 'when inviting a new user' do
      let!(:user) { create :user, status: User::TEMPORARY_STATUS, invite_token: Devise.friendly_token }
      let(:site_membership) { create :site_membership, user: user }

      it 'renders the headers' do
        expect(mail.subject).to eq subject
        expect(mail.to).to eq [user.email]
        expect(mail.from).to eq ['contact@hellobar.com']
      end

      it 'renders the body' do
        expect(mail.body.encoded).to include site.normalized_url
        expect(mail.body.encoded).to include oauth_login_url(action: 'google_oauth2')
        expect(mail.body.encoded).to include invite_user_url(invite_token: user.invite_token)
      end
    end
  end
end
