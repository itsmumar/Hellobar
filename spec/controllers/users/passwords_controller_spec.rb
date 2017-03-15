require 'spec_helper'

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

    it "redirects if trying to reset with an email that's in the wordpress database" do
      expect(Hello::WordpressUser).to receive(:email_exists?).with('user@website.com').and_return(true)

      post :create, user: { email: 'user@website.com' }

      expect(response).to render_template('pages/redirect_forgot')
    end
  end
end
