require 'spec_helper'

describe Admin::AccessController do
  let!(:admin) { create(:admin) }

  describe 'POST do_reset_password' do
    it 'resets the password and redirects the admin with correct parameters' do
      stub_current_admin(admin)
      admin.should_receive(:reset_password!).with('newpass123')

      post :do_reset_password, existing_password: 'password', new_password: 'newpass123', new_password_again: 'newpass123'

      response.should redirect_to(admin_path)
    end

    it "errors if the admin doesn't know their existing password" do
      stub_current_admin(admin)
      admin.should_receive(:reset_password!).never

      post :do_reset_password, existing_password: 'iforgetmypassword', new_password: 'newpass123', new_password_again: 'newpass123'

      response.should render_template('reset_password')
    end
  end

  describe 'GET logout' do
    it 'logs the admin out' do
      stub_current_admin(admin)
      admin.should_receive(:logout!)

      get :logout_admin

      response.should redirect_to(admin_access_path)
    end

    it 'redirects if no admin is logged-in' do
      get :logout_admin
      response.should redirect_to(admin_access_path)
    end
  end

  describe 'POST process_step1' do
    it 'sends a "validate access code" email to admin if they need one' do
      Admin.stub(:find_by).with(email: admin.email).and_return(admin)
      admin.stub(:has_validated_access_token?).and_return(false)

      admin.should_receive(:send_validate_access_token_email!)

      post :process_step1, login_email: admin.email
    end
  end

  describe 'POST process_step2' do
    it 'logs in the admin with valid params' do
      session[:admin_access_email] = admin.email
      Admin.stub(:where).and_return([admin])
      admin.stub(:has_validated_access_token?).and_return(true)

      admin.should_receive(:validate_login).and_return(true)

      post :process_step2, admin_access_email: admin.email

      session[:admin_token].should == admin.session_token
      response.should redirect_to(admin_path)
    end

    it 'renders step 2 if login cannot be validated' do
      session[:admin_access_email] = admin.email
      Admin.stub(:where).and_return([admin])
      admin.stub(:has_validated_access_token?).and_return(true)

      admin.should_receive(:validate_login).and_return(false)

      post :process_step2, admin_access_email: admin.email

      session[:admin_token].should_not == admin.session_token
      response.should render_template('step2')
    end
  end

  describe 'GET validate_access_token' do
    it 'moves on to step two if valid params are passed' do
      Admin.stub(:where).and_return([admin])
      admin.stub(:has_validated_access_token?).and_return(true)
      admin.stub(:needs_otp_code?).and_return(false)

      admin.should_receive(:validate_access_token).and_return(true)

      get :validate_access_token, email: admin.email, key: 'key', timestamp: 1

      response.should render_template('step2')
    end
  end
end
