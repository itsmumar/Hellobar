describe 'Users::Passwords requests' do
  let(:user) { create :user }

  around { |example| perform_enqueued_jobs(&example) }

  describe 'POST create' do
    it 'sends a password reset email' do
      expect(PasswordMailer)
        .to receive(:reset)
        .with(user, anything)
        .and_call_original.twice

      post user_password_path, user: { email: user.email }

      expect(last_email_sent)
        .to have_subject 'Reset your password'
    end

    it 'responds with a redirect' do
      post user_password_path, user: { email: user.email }

      expect(response).to redirect_to new_user_session_path
    end
  end
end
