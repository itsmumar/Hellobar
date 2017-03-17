require 'spec_helper'

describe Admin do
  let!(:admin) { create :admin, session_last_active: Time.now }

  it 'can create a new record from email and initial password' do
    admin = Admin.make!('newadmin@polymathic.me', '5553211234')
    admin.should be_valid
  end

  describe '::validate_session' do
    it 'returns an admin with valid access token and session token' do
      Admin.validate_session(admin.session_access_token, admin.session_token).should == admin
    end

    it 'returns nil if admin not found' do
      Admin.validate_session('gibber', 'ish').should be_nil
    end

    it 'returns nil if the session is too old' do
      admin.should_receive(:session_last_active).and_return(Time.now - Admin::MAX_SESSION_TIME - 1.hour)
      Admin.should_receive(:find_by).with(session_access_token: 'foo', session_token: 'bar').and_return(admin)

      result = Admin.validate_session('foo', 'bar')
      result.should be_nil
    end

    it 'returns nil if the admin is locked' do
      admin.should_receive(:locked?).and_return(true)
      Admin.should_receive(:find_by).with(session_access_token: 'foo', session_token: 'bar').and_return(admin)

      result = Admin.validate_session('foo', 'bar')
      result.should be_nil
    end

    it 'returns nil if session is old AND admin is locked' do
      admin.stub(:locked?).and_return(true)
      admin.stub(:session_last_active).and_return(Time.now - Admin::MAX_SESSION_TIME - 1.hour)
      Admin.should_receive(:find_by).with(session_access_token: 'foo', session_token: 'bar').and_return(admin)

      result = Admin.validate_session('foo', 'bar')
      result.should be_nil
    end

    it 'bumps session_last_active is session is still good' do
      admin.should_receive(:session_heartbeat!)
      Admin.should_receive(:find_by).with(session_access_token: 'foo', session_token: 'bar').and_return(admin)

      Admin.validate_session('foo', 'bar')
    end
  end

  describe 'needs_otp_code?' do
    it "returns false if we've both authentication_code and rotp_secret_base added" do
      admin.stub(:rotp_secret_base).and_return('whateverkey')
      admin.stub(:authentication_code).and_return('123')
      admin.needs_otp_code?.should be_false
    end

    it "returns true if don't have rotp_secret_base added" do
      admin.stub(:rotp_secret_base).and_return(nil)
      admin.needs_otp_code?.should be_true
    end

    it "returns true if we don't have authentication_code added" do
      admin.stub(:authentication_code).and_return(nil)
      admin.needs_otp_code?.should be_true
    end
  end

  it 'send_validate_access_token_email! sends an email to the admin with correct URLs' do
    Pony.should_receive(:mail)
    admin.send_validate_access_token_email!('token')
  end

  describe 'validate_login' do
    before(:each) do
      admin.valid_access_tokens = { 'token' => [Time.now.to_i, Time.now.to_i] }
    end

    it 'locks the admin if attempting to log in too many times' do
      admin.update_attribute(:login_attempts, Admin::MAX_LOGIN_ATTEMPTS)
      admin.should_not be_locked

      admin.validate_login('token', 'password', '123')

      admin.should be_locked
      admin.login_attempts.should == Admin::MAX_LOGIN_ATTEMPTS + 1
    end

    it 'returns false if locked' do
      admin.stub(:locked?).and_return(true)
      admin.validate_login('token', 'password', admin.initial_password).should be_false
    end

    it 'returns false if otp is not valid' do
      admin.stub(:needs_otp_code?).and_return(true)
      admin.validate_login('token', 'password', 'notthecode').should be_false
    end

    it 'returns false if the wrong password is used' do
      admin.validate_login('token', 'notthepassword', admin.initial_password).should be_false
    end

    it 'returns false if the access token is invalid' do
      admin.validate_login('notthetoken', 'password', admin.initial_password).should be_false
    end

    it 'logs the admin in if all params are valid' do
      admin.stub(:needs_otp_code?).and_return(true)
      admin.stub(:valid_authentication_otp?).with('123').and_return(true)
      admin.should_receive(:login!)
      admin.validate_login('token', 'password', '123').should be_true
    end
  end

  it 'reset_password! resets password and notifies admin via email' do
    admin.password_last_reset.should be < 1.minute.ago

    Pony.should_receive(:mail)
    admin.should_receive(:password=).with('new_password')

    admin.reset_password!('new_password')

    admin.password_last_reset.should be > 1.minute.ago
  end

  it 'login! logs the admin in' do
    admin.update_attributes(
      login_attempts: 2,
      session_token: '',
      session_access_token: ''
    )

    admin.should_receive(:set_valid_access_token)
    admin.should_receive(:session_heartbeat!)

    admin.login!('new_token')
    admin.reload

    admin.login_attempts.should == 0
    admin.session_token.should_not be_blank
    admin.session_access_token.should_not be_blank
    admin.authentication_code.should be_blank
  end

  describe '#unlock!' do
    it 'should set admin to unlocked' do
      admin = create(:admin, locked: true)
      admin.unlock!
      expect(admin.reload.locked).to be(false)
    end

    it 'should set admin login attempts to 0' do
      admin = create(:admin, login_attempts: 2)
      admin.unlock!
      expect(admin.reload.login_attempts).to be(0)
    end
  end

  describe '.unlock_all!' do
    it 'should set all admins to unlocked' do
      create(:admin, locked: true)
      Admin.unlock_all!
      expect(Admin.where(locked: true).count).to be(0)
    end

    it 'should set all admin login attempts to 0' do
      create(:admin, login_attempts: 2)
      Admin.unlock_all!
      expect(Admin.where('login_attempts > 0').count).to be(0)
    end
  end
end
