describe Users::PasswordsController do
  before(:each) do
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe 'POST create' do
    it 'sends a password reset with valid params' do
      user = create(:user)

      expect(MailerGateway).to receive(:send_email).with('Reset Password', user.email, anything)

      post :create, user: { email: user.email }
    end
  end
end
