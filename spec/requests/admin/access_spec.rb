describe 'Admin::Access requests' do
  let(:correct_password) { 'secure_password' }
  let(:password) { correct_password }
  let(:email) { admin.email }
  let!(:admin) { create(:admin, password: correct_password) }

  describe 'POST do_reset_password' do
    let(:do_reset_password) { post admin_reset_password_path, params }

    before do
      stub_current_admin(admin)
    end

    context 'with correct parameters' do
      let(:params) { { existing_password: password, new_password: 'newpass123', new_password_again: 'newpass123' } }

      before { expect(Pony).to receive(:mail).with(hash_including(to: admin.email)) }

      it 'resets password' do
        expect { do_reset_password }
          .to change { admin.reload.password_hashed }
      end

      it 'redirects to admin_path' do
        do_reset_password
        expect(response).to redirect_to(admin_path)
      end
    end

    shared_context 'renders error' do
      it 'sets flash[:error]' do
        do_reset_password
        expect(flash[:error]).to eql error
      end

      it 'does not reset password' do
        expect(admin).to receive(:reset_password!).never
        do_reset_password
      end

      it 'renders reset_password template' do
        do_reset_password
        expect(response).to have_rendered :reset_password
      end
    end

    context 'when passwords mismatch' do
      let(:params) { { existing_password: password, new_password: 'newpass', new_password_again: 'newpass123' } }
      let(:error) { 'Your new passwords did not match each other' }

      include_context 'renders error'
    end

    context 'with wrong existing password' do
      let(:params) { { existing_password: 'wrong', new_password: 'newpass123', new_password_again: 'newpass123' } }
      let(:error) { 'Your existing password is incorrect' }

      include_context 'renders error'
    end

    context 'with too short password' do
      let(:params) { { existing_password: password, new_password: 'newpass', new_password_again: 'newpass' } }
      let(:error) { 'New password must be at least 8 chars' }

      include_context 'renders error'
    end

    context 'with same password' do
      let(:params) { { existing_password: password, new_password: password, new_password_again: password } }
      let(:error) { 'New password must be different than existing password.' }

      include_context 'renders error'
    end
  end

  describe 'GET logout' do
    let(:logout_admin) { get admin_logout_path }

    it 'logs the admin out' do
      stub_current_admin(admin)

      logout_admin

      expect(response).to redirect_to(admin_access_path)
      expect(flash['success']).to eql 'You are now logged out.'
    end

    it 'redirects if no admin is logged-in' do
      logout_admin
      expect(response).to redirect_to(admin_access_path)
      expect(flash['alert']).to eql 'Access denied'
    end
  end

  describe 'POST process_step1' do
    let(:process_step1) { post admin_access_path, admin_session: { email: email, password: password } }

    shared_examples 'auditable' do
      let(:last_login_attempt) { AdminLoginAttempt.last }

      it 'records login attempt' do
        expect { process_step1 }.to change(AdminLoginAttempt, :count).by(1)
        expect(last_login_attempt.email).to eql email
        expect(last_login_attempt.ip_address).to eql request.remote_ip
      end
    end

    shared_examples 'render_error' do
      it 'sets flash[:error]' do
        process_step1
        expect(flash[:error]).to eq('Invalid email or password')
      end

      it 'renders step1 template again' do
        process_step1
        expect(response).to have_rendered :step1
      end
    end

    context 'when email exists' do
      include_examples 'auditable'

      context 'when OTP is enabled' do
        before do
          allow(Admin).to receive(:otp_enabled?).and_return(true)
        end

        it 'stores admin.id in session' do
          process_step1
          expect(session[:login_admin]).to eq(admin.id)
        end

        it 'redirects to OTP step' do
          process_step1
          expect(response).to redirect_to(admin_otp_path)
        end
      end

      context 'when OTP is disabled' do
        before do
          allow(Admin).to receive(:otp_enabled?).and_return(false)
        end

        it 'does not store admin.id in session' do
          process_step1
          expect(session[:login_admin]).to be_blank
        end

        it 'redirects to admin home' do
          process_step1
          expect(response).to redirect_to(admin_path)
        end
      end

      context 'and admin is locked' do
        let(:admin) { create :admin, :locked }

        it 'redirects to admin_locked_path' do
          process_step1
          expect(response).to redirect_to admin_locked_path
        end
      end
    end

    context 'when email does not exist' do
      let(:email) { 'wrong@email.com' }

      include_examples 'auditable'
      include_examples 'render_error'
    end

    context 'when blank email' do
      let(:email) { '' }

      it 'redirects to admin_access_path' do
        process_step1
        expect(response).to redirect_to admin_access_path
      end
    end

    context 'when password is invalid' do
      let(:password) { 'wrong_password' }

      include_examples 'auditable'
      include_examples 'render_error'
    end

    context 'when admin is signed in' do
      before { stub_current_admin(admin) }

      it 'redirects to admin_path' do
        process_step1
        expect(response).to redirect_to admin_path
      end
    end
  end

  describe 'POST process_step2' do
    let(:otp) { 123_456 }
    let(:otp_valid) { true }
    let(:policy) { instance_double(AdminAuthenticationPolicy, otp_valid?: otp_valid, generate_otp: 'abc=') }

    let(:process_step2) { post admin_authenticate_path, admin_session: { otp: '123 456' } }

    before do
      allow(Admin).to receive(:otp_enabled?).and_return(true)
      allow(AdminAuthenticationPolicy).to receive(:new).with(admin).and_return(policy)
    end

    context 'without step1' do
      it 'redirects to admin_access_path' do
        process_step2
        expect(response).to redirect_to admin_access_path
      end
    end

    context 'with step1' do
      before do
        post admin_access_path, admin_session: { email: email, password: password }
      end

      context 'when OTP is valid' do
        it 'redirects to admin_path' do
          process_step2
          expect(response).to redirect_to admin_path
        end

        it 'sets session[:admin_token]' do
          process_step2
          expect(session[:admin_token]).to be_present
        end
      end

      context 'when OTP is invalid' do
        let(:otp_valid) { false }

        it 'sets flash[:error]' do
          process_step2
          expect(flash[:error]).to eq('Invalid OTP')
        end

        it 'renders step2 template again' do
          process_step2
          expect(response).to have_rendered :step2
        end

        it 'does not set session[:admin_token]' do
          process_step2
          expect(session[:admin_token]).to be_blank
        end
      end
    end
  end

  describe 'POST lockdown', :freeze do
    let!(:timestamp) { Time.current.to_i }
    let!(:admins) { create_list :admin, 2 }
    let(:key) { Admin.lockdown_key(email, timestamp) }
    let(:lockdown) { get admin_lockdown_path(email: email, key: key, timestamp: timestamp) }

    context 'with correct key and timestamp' do
      it 'locks all admins' do
        expect { lockdown }.to change(Admin.locked, :count).from(0).to(3)
        expect(response.body).to eql 'Admins have been successfully locked down'
      end

      context 'and key is expired' do
        let!(:timestamp) { 2.hours.ago.to_i }

        it 'does not lock admins' do
          expect { lockdown }.not_to change(Admin.locked, :count)
          expect(response.body).to eql 'Admins could not be locked down'
        end
      end
    end

    context 'with wrong key' do
      let!(:key) { 'wrong' }

      it 'does not lock admins' do
        expect { lockdown }.not_to change(Admin.locked, :count)
        expect(response.body).to eql 'Admins could not be locked down'
      end
    end
  end
end
