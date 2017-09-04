describe PasswordMailer do
  describe '#reset' do
    let(:user) { create :user }
    let(:reset_password_token) { 'reset_password_token' }
    let(:mail) { PasswordMailer.reset user, reset_password_token }

    let(:subject) { 'Reset your password' }

    it 'renders the headers' do
      expect(mail.subject).to eq subject
      expect(mail.to).to eq [user.email]
      expect(mail.from).to eq ['support@hellobar.com']
    end

    it 'renders the body' do
      expect(mail.body.encoded)
        .to include edit_user_password_url(reset_password_token: reset_password_token)
    end

    context 'when user is an oauth user' do
      before { allow(user).to receive(:oauth_user?).and_return true }

      it 'renders the headers' do
        expect(mail.subject).to eq subject
        expect(mail.to).to eq [user.email]
        expect(mail.from).to eq ['support@hellobar.com']
      end

      it 'renders the body' do
        expect(mail.body.encoded).to include oauth_login_url(action: 'google_oauth2')
      end
    end
  end
end
