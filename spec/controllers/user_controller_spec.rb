require 'spec_helper'

describe UserController do
  fixtures :all

  before(:each) do
    @user = users(:joey)
  end

  describe "PUT update" do
    it "allows the user to change their password" do
      stub_current_user(@user)
      original_hash = @user.encrypted_password

      put :update, :user => {:password => "asdfffff", :password_confirmation => "asdfffff"}

      @user.reload.encrypted_password.should_not == original_hash
    end

    it "allows the user to change other settings with blank password params" do
      stub_current_user(@user)

      put :update, :user => {:first_name => "Sexton", :last_name => "Hardcastle", :password => "", :password_confirmation => ""}

      @user.reload.first_name.should == "Sexton"
      @user.reload.last_name.should == "Hardcastle"
    end
  end
end
