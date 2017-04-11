describe Admin do
  let!(:admin) { create :admin }

  it 'can create a new record from email and initial password' do
    admin = Admin.make!('newadmin@polymathic.me', '5553211234')

    expect(admin).to be_valid
  end

  describe '#validate_session' do
    it 'returns nil if token is nil or empty' do
      create :admin, session_token: nil

      expect(Admin.validate_session(nil)).to be_nil
      expect(Admin.validate_session("")).to be_nil
    end

    it 'returns an admin with valid access token and session token' do
      expect(Admin.validate_session(admin.session_token)).to eq(admin)
    end

    it 'returns nil if admin not found' do
      expect(Admin.validate_session('ish')).to be_nil
    end

    it 'returns nil if the session is too old' do
      expect(admin).to receive(:session_last_active).and_return(Time.current - Admin::MAX_SESSION_TIME - 1.hour)
      expect(Admin).to receive(:find_by).with(session_token: 'bar').and_return(admin)

      result = Admin.validate_session('bar')
      expect(result).to be_nil
    end

    it 'returns nil if the admin is locked' do
      expect(admin).to receive(:locked?).and_return(true)
      expect(Admin).to receive(:find_by).with(session_token: 'bar').and_return(admin)

      result = Admin.validate_session('bar')
      expect(result).to be_nil
    end

    it 'returns nil if session is old AND admin is locked' do
      allow(admin).to receive(:locked?).and_return(true)
      allow(admin).to receive(:session_last_active).and_return(Time.current - Admin::MAX_SESSION_TIME - 1.hour)
      expect(Admin).to receive(:find_by).with(session_token: 'bar').and_return(admin)

      result = Admin.validate_session('bar')
      expect(result).to be_nil
    end

    it 'bumps session_last_active is session is still good' do
      expect(admin).to receive(:session_heartbeat!)
      expect(Admin).to receive(:find_by).with(session_token: 'bar').and_return(admin)

      Admin.validate_session('bar')
    end
  end

  describe 'needs_otp_code?' do
    it "returns false if we've both authentication_code and rotp_secret_base added" do
      allow(admin).to receive(:rotp_secret_base).and_return('whateverkey')
      allow(admin).to receive(:authentication_code).and_return('123')
      expect(admin.needs_otp_code?).to be_falsey
    end

    it "returns true if don't have rotp_secret_base added" do
      allow(admin).to receive(:rotp_secret_base).and_return(nil)
      expect(admin.needs_otp_code?).to be_truthy
    end

    it "returns true if we don't have authentication_code added" do
      allow(admin).to receive(:authentication_code).and_return(nil)
      expect(admin.needs_otp_code?).to be_truthy
    end
  end

  describe 'validate_login' do
    it 'locks the admin if attempting to log in too many times' do
      admin.update_attribute(:login_attempts, Admin::MAX_LOGIN_ATTEMPTS)
      expect(admin).not_to be_locked

      admin.validate_login('password', '123')

      expect(admin).to be_locked
      expect(admin.login_attempts).to eq(Admin::MAX_LOGIN_ATTEMPTS + 1)
    end

    it 'returns false if locked' do
      allow(admin).to receive(:locked?).and_return(true)
      expect(admin.validate_login('password', admin.initial_password)).to be_falsey
    end

    it 'returns false if otp is not valid' do
      allow(admin).to receive(:needs_otp_code?).and_return(true)
      allow_any_instance_of(AdminAuthenticationPolicy).to receive(:otp_valid?).and_return(false)
      expect(admin.validate_login('password', 'notthecode')).to be_falsey
    end

    it 'returns false if the wrong password is used' do
      expect(admin.validate_login('notthepassword', admin.initial_password)).to be_falsey
    end

    it 'logs the admin in if all params are valid' do
      allow(admin).to receive(:needs_otp_code?).and_return(true)
      allow(admin).to receive(:valid_authentication_otp?).with('123').and_return(true)
      expect(admin).to receive(:login!)
      expect(admin.validate_login('password', '123')).to be_truthy
    end
  end

  it 'reset_password! resets password and notifies admin via email' do
    expect(admin.password_last_reset).to be < 1.minute.ago

    expect(Pony).to receive(:mail)
    expect(admin).to receive(:password=).with('new_password')

    admin.reset_password!('new_password')

    expect(admin.password_last_reset).to be > 1.minute.ago
  end

  it 'login! logs the admin in' do
    admin.update_attributes(login_attempts: 2, session_token: '')

    expect(admin).to receive(:session_heartbeat!)

    admin.login!
    admin.reload

    expect(admin.login_attempts).to eq(0)
    expect(admin.session_token).not_to be_blank
    expect(admin.authentication_code).to be_blank
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
