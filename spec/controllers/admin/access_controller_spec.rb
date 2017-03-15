require 'spec_helper'

describe Admin::AccessController do
  let!(:admin) { create(:admin) }

  describe 'POST do_reset_password' do
    it 'resets the password and redirects the admin with correct parameters' do
      stub_current_admin(admin)
      expect(admin).to receive(:reset_password!).with('newpass123')

      post :do_reset_password, existing_password: 'password', new_password: 'newpass123', new_password_again: 'newpass123'

      expect(response).to redirect_to(admin_path)
    end

    it "errors if the admin doesn't know their existing password" do
      stub_current_admin(admin)
      expect(admin).to receive(:reset_password!).never

      post :do_reset_password, existing_password: 'iforgetmypassword', new_password: 'newpass123', new_password_again: 'newpass123'

      expect(response).to render_template('reset_password')
    end
  end

  describe 'GET logout' do
    it 'logs the admin out' do
      stub_current_admin(admin)
      expect(admin).to receive(:logout!)

      get :logout_admin

      expect(response).to redirect_to(admin_access_path)
    end

    it 'redirects if no admin is logged-in' do
      get :logout_admin
      expect(response).to redirect_to(admin_access_path)
    end
  end

  describe 'POST process_step1' do
    it 'sends a "validate access code" email to admin if they need one' do
      allow(Admin).to receive(:find_by).with(email: admin.email).and_return(admin)
      allow(admin).to receive(:has_validated_access_token?).and_return(false)

      expect(admin).to receive(:send_validate_access_token_email!)

      post :process_step1, login_email: admin.email
    end
  end

  describe 'POST process_step2' do
    it 'logs in the admin with valid params' do
      session[:admin_access_email] = admin.email
      allow(Admin).to receive(:where).and_return([admin])
      allow(admin).to receive(:has_validated_access_token?).and_return(true)

      expect(admin).to receive(:validate_login).and_return(true)

      post :process_step2, admin_access_email: admin.email

      expect(session[:admin_token]).to eq(admin.session_token)
      expect(response).to redirect_to(admin_path)
    end

    it 'renders step 2 if login cannot be validated' do
      session[:admin_access_email] = admin.email
      allow(Admin).to receive(:where).and_return([admin])
      allow(admin).to receive(:has_validated_access_token?).and_return(true)

      expect(admin).to receive(:validate_login).and_return(false)

      post :process_step2, admin_access_email: admin.email

      expect(session[:admin_token]).not_to eq(admin.session_token)
      expect(response).to render_template('step2')
    end
  end

  describe 'GET validate_access_token' do
    it 'moves on to step two if valid params are passed' do
      allow(Admin).to receive(:where).and_return([admin])
      allow(admin).to receive(:has_validated_access_token?).and_return(true)
      allow(admin).to receive(:needs_otp_code?).and_return(false)

      expect(admin).to receive(:validate_access_token).and_return(true)

      get :validate_access_token, email: admin.email, key: 'key', timestamp: 1

      expect(response).to render_template('step2')
    end
  end
end
