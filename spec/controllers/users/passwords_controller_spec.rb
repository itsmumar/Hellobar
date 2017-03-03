require 'spec_helper'

describe Users::PasswordsController do
  fixtures :all

  before(:each) do
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe 'POST create' do
    it 'sends a password reset with valid params' do
      user = users(:joey)

      MailerGateway.should_receive(:send_email).with('Reset Password', user.email, anything)

      post :create, :user => {:email => user.email}
    end

    it "redirects if trying to reset with an email that's in the wordpress database" do
      Hello::WordpressUser.should_receive(:email_exists?).with('user@website.com').and_return(true)

      post :create, :user => {:email => 'user@website.com'}

      response.should render_template('pages/redirect_forgot')
    end
  end
end
