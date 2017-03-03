require 'spec_helper'

describe UserController do
  fixtures :all

  describe 'PUT update' do
    context 'user is active' do
      before do
        @user = users(:joey)
        @current_password = 'current_pass'

        # update password only if it was changed in some test
        @user.update_attributes(password: @current_password, password_confirmation: @current_password) unless @user.valid_password?(@current_password)

        stub_current_user(@user)
      end

      it 'rejects password change when incorrect current_password' do
        put :update, user: { password: 'asdfffff', password_confirmation: 'asdfffff', current_password: 'oops' }

        @user.reload.valid_password?(@current_password).should be_true
      end

      it 'allows the user to change their password with correct current_password' do
        new_password = 'asdfffff'
        update_params = { password: new_password, password_confirmation: new_password, current_password: @current_password }
        put :update, user: update_params

        @user.reload.valid_password?(new_password).should be_true
      end

      it 'allows the user to change other settings with blank password params' do
        put :update, user: { first_name: 'Sexton', last_name: 'Hardcastle', password: '', password_confirmation: '' }

        @user.reload.first_name.should == 'Sexton'
        @user.reload.last_name.should == 'Hardcastle'
      end

      it 'sets the timezone on all sites when passed in' do
        put :update, user: { timezone: 'America/Chicago' }

        @user.sites.reload.map(&:timezone).should == ['America/Chicago', 'America/Chicago', 'America/Chicago']
      end

      it 'does not override a sites timezone if already set' do
        @user.sites.first.update_attribute :timezone, 'FIRST'

        put :update, user: { timezone: 'America/Chicago' }

        @user.sites.reload.map(&:timezone).should == ['FIRST', 'America/Chicago', 'America/Chicago']
      end
    end

    context 'user is temporary' do
      before do
        @user = users(:temporary)
        stub_current_user(@user)
      end

      it 'allows user to set their email and passwore, and activate' do
        original_hash = @user.encrypted_password

        put :update, user: { email: 'myrealemail@gmail.com', password: 'asdfffff' }

        @user.reload

        @user.encrypted_password.should_not == original_hash
        @user.email.should == 'myrealemail@gmail.com'
        @user.status.should == User::ACTIVE_STATUS
      end

      it 'does not update the user if the password param is blank' do
        put :update, user: { email: 'myrealemail@gmail.com' }

        @user.reload

        @user.email.should_not == 'myrealemail@gmail.com'
        @user.status.should == User::TEMPORARY_STATUS
      end

      it 'does not update the user if the email param is blank' do
        original_hash = @user.encrypted_password

        put :update, user: { password: 'asdffff' }

        @user.reload

        @user.encrypted_password.should == original_hash
        @user.status.should == User::TEMPORARY_STATUS
      end
    end
  end
end
