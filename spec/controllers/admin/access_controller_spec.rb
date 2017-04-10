describe Admin::AccessController do
  let!(:admin) { create(:admin) }

  describe 'POST do_reset_password' do
    let(:do_reset_password) { post :do_reset_password, params }

    before do
      stub_current_admin(admin)
    end

    context 'with correct parameters' do
      let(:params) { { existing_password: 'password', new_password: 'newpass123', new_password_again: 'newpass123' } }

      before { expect(Pony).to receive(:mail).with(hash_including(to: admin.email)) }

      it 'resets password' do
        expect { do_reset_password }
          .to change { admin.reload.password_hashed }
          .and change { admin.reload.password_last_reset }
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
      let(:params) { { existing_password: 'password', new_password: 'newpass', new_password_again: 'newpass123' } }
      let(:error) { 'Your new passwords did not match each other' }

      include_context 'renders error'
    end

    context 'with wrong existing password' do
      let(:params) { { existing_password: 'wrong', new_password: 'newpass123', new_password_again: 'newpass123' } }
      let(:error) { 'Your existing password is incorrect' }

      include_context 'renders error'
    end

    context 'with too short password' do
      let(:params) { { existing_password: 'password', new_password: 'newpass', new_password_again: 'newpass' } }
      let(:error) { 'New password must be at least 8 chars' }

      include_context 'renders error'
    end

    context 'with same password' do
      let(:params) { { existing_password: 'password', new_password: 'password', new_password_again: 'password' } }
      let(:error) { 'New password must be different than existing password.' }

      include_context 'renders error'
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
    let(:email) { admin.email }
    let(:process_step1) { post :process_step1, login_email: email }

    it 'records login attepmt' do
      expect(Admin).to receive(:record_login_attempt)
      process_step1
    end

    it 'stores admin_access_email in session' do
      process_step1
      expect(session[:admin_access_email]).to eql admin.email
    end

    context 'with blank email' do
      let(:email) { '' }

      it 'redirects to admin_access_path' do
        process_step1
        expect(response).to redirect_to admin_access_path
      end
    end

    context 'when email exists' do
      it 'renders step2' do
        process_step1
        expect(response).to have_rendered :step2
      end

      it 'assigns @admin' do
        process_step1
        expect(assigns(:admin)).to eql admin
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

      it 'renders step2' do
        process_step1
        expect(response).to have_rendered :step2
      end

      it 'does not assign @admin' do
        process_step1
        expect(assigns(:admin)).to be_nil
      end
    end
  end

  describe 'POST process_step2' do
    let(:email) { admin.email }
    let(:process_step2) { post :process_step2, admin_password: 'password', otp: '123 456' }

    before { session[:admin_access_email] = email }

    context 'with blank session[:admin_access_email]' do
      before { session[:admin_access_email] = '' }

      it 'redirects to admin_access_path' do
        process_step2
        expect(response).to redirect_to admin_access_path
      end
    end

    context 'when email exists' do
      context 'and password is correct' do
        it 'redirects to admin_path' do
          process_step2
          expect(response).to redirect_to admin_path
        end

        it 'sets session[:admin_token]' do
          process_step2
          expect(session[:admin_token]).to be_present
        end
      end

      context 'and admin is locked' do
        let(:admin) { create :admin, :locked }

        it 'redirects to admin_locked_path' do
          process_step2
          expect(response).to redirect_to admin_locked_path
        end
      end

      context 'and password is not correct' do
        let(:process_step2) { post :process_step2, admin_password: 'wrong', otp: '123 456' }

        it 'renders error' do
          process_step2
          expect(flash[:error]).to eql 'Invalid OTP or password or too many attempts'
        end
      end

      context 'and otp is not correct' do
        before { allow_any_instance_of(AdminAuthenticationPolicy).to receive(:otp_valid?).and_return(false) }

        it 'renders error' do
          process_step2
          expect(flash[:error]).to eql 'Invalid OTP or password or too many attempts'
        end
      end
    end

    context 'when email does not exist' do
      let(:email) { 'wrong@email.com' }

      it 'renders step2' do
        process_step2
        expect(response).to have_rendered :step2
      end

      it 'does not assign @admin' do
        process_step2
        expect(assigns(:admin)).to be_nil
      end
    end
  end
end
