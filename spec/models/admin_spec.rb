describe Admin do
  let(:password) { 'asdqwe!!' }
  let!(:admin) { create(:admin, password: password) }

  it 'can create a new record from email and initial password' do
    admin = Admin.make!('newadmin@polymathic.me', '5553211234')

    expect(admin).to be_valid
  end

  describe '#validate_session' do
    it 'returns nil if token is nil or empty' do
      create :admin, session_token: nil

      expect(Admin.validate_session(nil)).to be_nil
      expect(Admin.validate_session('')).to be_nil
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

  describe '#validate_password!' do
    context 'when valid password given' do
      it 'returns true' do
        expect(admin.validate_password!(password)).to be_truthy
      end

      it 'resets login_attempts counter' do
        admin.increment(:login_attempts)
        admin.validate_password!(password)

        expect(admin.login_attempts).to eq(0)
      end
    end

    context 'when invalid password given' do
      let(:invalid_password) { 'p@ssword' }

      it 'returns false' do
        expect(admin.validate_password!(invalid_password)).to be_falsey
      end

      it 'increments login_attempts counter' do
        expect { admin.validate_password!(invalid_password) }.to change { admin.login_attempts }.by(1)
      end

      context 'when login_attempts exceeds the limit' do
        before do
          admin.update_attribute(:login_attempts, Admin::MAX_LOGIN_ATTEMPTS - 1)
        end

        it 'locks the account' do
          expect { admin.validate_password!(invalid_password) }.to change { admin.locked? }.to(true)
        end
      end
    end
  end

  describe '#validate_otp!' do
    let(:otp) { 123 }
    let(:otp_valid) { true }
    let(:policy) { instance_double(AdminAuthenticationPolicy, otp_valid?: otp_valid) }

    before do
      allow(AdminAuthenticationPolicy).to receive(:new).with(admin).and_return(policy)
    end

    context 'when OTP is enabled' do
      before do
        allow(admin).to receive(:otp_enabled?).and_return(true)
      end

      context 'when given OTP is valid' do
        it 'returns true' do
          expect(admin.validate_otp!(otp)).to be_truthy
        end

        it 'updates authentication_code' do
          expect { admin.validate_otp!(otp) }.to change { admin.authentication_code }
        end
      end

      context 'when given OTP is invalid' do
        let(:otp_valid) { false }

        it 'returns false' do
          expect(admin.validate_otp!(otp)).to be_falsey
        end

        it 'does not update authentication_code' do
          expect { admin.validate_otp!(otp) }.not_to change { admin.authentication_code }
        end
      end
    end

    context 'when OTP is disabled' do
      before do
        allow(admin).to receive(:otp_enabled?).and_return(false)
      end

      context 'when given OTP is valid' do
        it 'returns true' do
          expect(admin.validate_otp!(otp)).to be_truthy
        end

        it 'does not update authentication_code' do
          expect { admin.validate_otp!(otp) }.not_to change { admin.authentication_code }
        end
      end

      context 'when given OTP is invalid' do
        let(:otp_valid) { false }

        it 'returns true' do
          expect(admin.validate_otp!(otp)).to be_truthy
        end

        it 'does not update authentication_code' do
          expect { admin.validate_otp!(otp) }.not_to change { admin.authentication_code }
        end
      end
    end
  end

  it 'reset_password! resets password and notifies admin via email' do
    expect(Pony).to receive(:mail)

    expect { admin.reset_password!('new_password') }
      .to change(admin, :password_hashed)
  end

  describe '#login!' do
    it 'generates session_token' do
      admin.login!
      expect(admin.session_token).to be_present
    end

    it 'updates existing session_token' do
      admin.login!

      expect { admin.login! }.to change { admin.session_token }
    end
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
