describe Users::PasswordsController do
  let(:user) { create :user }

  describe 'POST create' do
    it 'sends a password reset email' do
      expect(PasswordMailer)
        .to receive(:reset)
        .with(user, anything)
        .and_return double(deliver_later: true)

      post user_password_path, user: { email: user.email }
    end

    it 'responds with a redirect' do
      post user_password_path, user: { email: user.email }

      expect(response).to redirect_to new_user_session_path
    end
  end
end
