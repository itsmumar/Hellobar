require 'spec_helper'

describe UserController do
  fixtures :all

  describe "PUT update" do
    context 'user is active' do
      before do
        @user = users(:joey)
        stub_current_user(@user)
      end

      it "allows the user to change their password" do
        original_hash = @user.encrypted_password

        put :update, :user => {:password => "asdfffff", :password_confirmation => "asdfffff" }

        @user.reload.encrypted_password.should_not == original_hash
      end

      it "allows the user to change other settings with blank password params" do
        put :update, :user => {:first_name => "Sexton", :last_name => "Hardcastle", :password => "", :password_confirmation => "" }

        @user.reload.first_name.should == "Sexton"
        @user.reload.last_name.should == "Hardcastle"
      end
    end

    context 'user is temporary' do
      before do
        @user = users(:temporary)
        stub_current_user(@user)
      end

      it "allows user to set their email and passwore, and activate" do
        original_hash = @user.encrypted_password

        put :update, :user => {:email => "myrealemail@gmail.com", :password => "asdfffff"}

        @user.reload

        @user.encrypted_password.should_not == original_hash
        @user.email.should == "myrealemail@gmail.com"
        @user.status.should == User::ACTIVE_STATUS
      end

      it 'does not update the user if the password param is blank' do
        put :update, :user => {:email => "myrealemail@gmail.com"}

        @user.reload

        @user.email.should_not == "myrealemail@gmail.com"
        @user.status.should == User::TEMPORARY_STATUS
      end

      it 'does not update the user if the email param is blank' do
        original_hash = @user.encrypted_password

        put :update, :user => {:password => "asdffff"}

        @user.reload

        @user.encrypted_password.should == original_hash
        @user.status.should == User::TEMPORARY_STATUS
      end
    end
  end
end
