describe 'User requests' do
  let(:user) { create :user, :with_site }

  context 'when unauthenticated' do
    before { create :credit_card, user: user }

    describe 'PUT :update' do
      it 'responds with a redirect to the login page' do
        post subscription_path

        expect(response).to redirect_to(/sign_in/)
      end
    end
  end

  context 'when authenticated' do
    before do
      login_as user, scope: :user, run_callbacks: false
    end

    describe 'PUT :update' do
      context 'when user is active' do
        let(:current_password) { 'current_pass' }
        let(:user) { create :user, password: current_password }
        let!(:sites) { create_list :site, 3, users: [user] }

        it 'rejects password change when incorrect current_password' do
          put user_path(user), user: { password: 'asdfffff', password_confirmation: 'asdfffff', current_password: 'oops' }

          expect(user.reload.valid_password?(current_password)).to be_truthy
        end

        it 'allows the user to change their password with correct current_password' do
          new_password = 'asdfffff'
          update_params = { password: new_password, password_confirmation: new_password, current_password: current_password }
          put user_path(user), user: update_params

          expect(user.reload.valid_password?(new_password)).to be_truthy
        end

        it 'allows the user to change other settings with blank password params' do
          put user_path(user), user: { first_name: 'Sexton', last_name: 'Hardcastle', password: '', password_confirmation: '' }

          expect(user.reload.first_name).to eq('Sexton')
          expect(user.reload.last_name).to eq('Hardcastle')
        end

        it 'sets the timezone on all sites when passed in' do
          put user_path(user), user: { timezone: 'America/Chicago' }

          expect(user.sites.reload.map(&:timezone)).to eq(['America/Chicago', 'America/Chicago', 'America/Chicago'])
        end

        it 'does not override a sites timezone if already set' do
          user.sites.first.update_attribute :timezone, 'FIRST'

          put user_path(user), user: { timezone: 'America/Chicago' }

          expect(user.sites.reload.map(&:timezone)).to eq(['FIRST', 'America/Chicago', 'America/Chicago'])
        end
      end

      context 'user is temporary' do
        let(:user) { create(:user, :temporary) }

        it 'allows user to set their email and passwore, and activate' do
          original_hash = user.encrypted_password

          put user_path(user), user: { email: 'myrealemail@gmail.com', password: 'asdfffff' }

          user.reload

          expect(user.encrypted_password).not_to eq(original_hash)
          expect(user.email).to eq('myrealemail@gmail.com')
          expect(user.status).to eq(User::ACTIVE_STATUS)
        end

        it 'does not update the user if the password param is blank' do
          put user_path(user), user: { email: 'myrealemail@gmail.com' }

          user.reload

          expect(user.email).not_to eq('myrealemail@gmail.com')
          expect(user.status).to eq(User::TEMPORARY_STATUS)
        end

        it 'does not update the user if the email param is blank' do
          original_hash = user.encrypted_password

          put user_path(user), user: { password: 'asdffff' }

          user.reload

          expect(user.encrypted_password).to eq(original_hash)
          expect(user.status).to eq(User::TEMPORARY_STATUS)
        end
      end
    end

    describe 'DELETE :destroy' do
      it 'responds with a redirect to get_started path' do
        delete user_path
        expect(response).to redirect_to get_started_path
      end

      it 'destroys user' do
        delete user_path
        expect(User.count).to be 0
      end

      context 'when ActiveRecord::RecordNotDestroyed error is raised' do
        before do
          expect(DestroyUser)
            .to receive_service_call.with(user)
            .and_raise(ActiveRecord::RecordNotDestroyed.new('message', user))
        end

        it 'renders errors' do
          delete user_path
          expect(User.count).to be 1
          expect(flash.now[:error]).to eql 'There was a problem deleting your account.'
        end
      end
    end
  end
end
