require 'spec_helper'

describe Admin do
  fixtures :all

  before(:each) do
    @admin = admins(:joey)
  end

  it "can create a new record from email and mobile phone" do
    admin = Admin.make!("newadmin@polymathic.me", "5553211234")
    admin.should be_valid
  end

  it "standardizes mobile phone on validation" do
    admin = Admin.new(:mobile_phone => "(555) 123-1234").tap{|a| a.valid?}
    admin.mobile_phone.should == "+15551231234"
  end

  describe "::validate_session" do
    it "returns an admin with valid access token and session token" do
      Admin.validate_session(@admin.session_access_token, @admin.session_token).should == @admin
    end

    it "returns nil if admin not found" do
      Admin.validate_session("gibber", "ish").should == nil
    end

    it "returns nil if the session is too old" do
      @admin.should_receive(:session_last_active).and_return(Time.now - Admin::MAX_SESSION_TIME - 1.hour)
      Admin.should_receive(:where).and_return([@admin])

      result = Admin.validate_session("foo", "bar")
      result.should == nil
    end

    it "returns nil if the admin is locked" do
      @admin.should_receive(:locked?).and_return(true)
      Admin.should_receive(:where).and_return([@admin])

      result = Admin.validate_session("foo", "bar")
      result.should == nil
    end

    it "returns nil if session is old AND admin is locked" do
      @admin.stub(:locked?).and_return(true)
      @admin.stub(:session_last_active).and_return(Time.now - Admin::MAX_SESSION_TIME - 1.hour)
      Admin.should_receive(:where).and_return([@admin])

      result = Admin.validate_session("foo", "bar")
      result.should == nil
    end

    it "bumps session_last_active is session is still good" do
      @admin.should_receive(:session_heartbeat!)
      Admin.should_receive(:where).and_return([@admin])

      Admin.validate_session("foo", "bar")
    end
  end

  describe "needs_mobile_code?" do
    it "returns false if we've validated this access token recently" do
      @admin.stub(:valid_access_tokens).and_return({"token" => [1.minute.ago.to_i, 1.minute.ago.to_i]})
      @admin.needs_mobile_code?("token").should be_false
    end

    it "returns true if we've never validated this access token" do
      @admin.stub(:valid_access_tokens).and_return({})
      @admin.needs_mobile_code?("token").should be_true
    end

    it "returns true if we validated this access token too long ago" do
      @admin.stub(:valid_access_tokens).and_return({"token" => [1.year.ago.to_i, 1.year.ago.to_i]})
      @admin.needs_mobile_code?("token").should be_true
    end
  end

  describe "send_new_mobile_code!" do
    it "sends a mobile code" do
      twilio = double(:twilio)
      Twilio::REST::Client.stub_chain("new.account.sms.messages").and_return(twilio)

      twilio.should_receive(:create).with(
        :body => anything,
        :to => @admin.mobile_phone,
        :from => "+14157952691"
      )

      @admin.send_new_mobile_code!
    end

    it "sends no code if the admin is locked" do
      @admin.stub(:locked?).and_return(true)
      @admin.send_new_mobile_code!.should be_false
    end

    it "locks the admin if too many codes have been sent" do
      @admin.mobile_codes_sent = Admin::MAX_MOBILE_CODES + 1

      Twilio::REST::Client.should_receive(:new).never
      @admin.should_receive(:lock!)

      @admin.send_new_mobile_code!
    end
  end

  it "send_validate_access_token_email! sends an email to the admin with correct URLs" do
    Pony.should_receive(:mail)
    @admin.send_validate_access_token_email!("token")
  end

  describe "validate_login" do
    before(:each) do
      @admin.valid_access_tokens = {"token" => [Time.now.to_i, Time.now.to_i]}
    end

    it "locks the admin if attempting to log in too many times" do
      @admin.update_attribute(:login_attempts, Admin::MAX_LOGIN_ATTEMPTS)
      @admin.should_not be_locked

      @admin.validate_login("token", "password", @admin.mobile_code)

      @admin.should be_locked
      @admin.login_attempts.should == Admin::MAX_LOGIN_ATTEMPTS + 1
    end

    it "returns false if locked" do
      @admin.stub(:locked?).and_return(true)
      @admin.validate_login("token", "password", @admin.mobile_code).should be_false
    end

    it "returns false if mobile code does not match" do
      @admin.stub(:needs_mobile_code?).and_return(true)
      @admin.validate_login("token", "password", "notthecode").should be_false
    end

    it "returns false if the wrong password is used" do
      @admin.validate_login("token", "notthepassword", @admin.mobile_code).should be_false
    end

    it "returns false if the access token is invalid" do
      @admin.validate_login("notthetoken", "password", @admin.mobile_code).should be_false
    end

    it "logs the admin in if all params are valid" do
      @admin.stub(:needs_mobile_code?).and_return(true)
      @admin.should_receive(:login!)
      @admin.validate_login("token", "password", @admin.mobile_code).should be_true
    end
  end

  it "reset_password! resets password and notifies admin via email" do
    @admin.password_last_reset.should be < 1.minute.ago

    Pony.should_receive(:mail)
    @admin.should_receive(:set_password!).with("new_password")

    @admin.reset_password!("new_password")

    @admin.password_last_reset.should be > 1.minute.ago
  end

  it "login! logs the admin in" do
    @admin.update_attributes(
      :mobile_codes_sent => 2,
      :login_attempts => 2,
      :session_token => "",
      :session_access_token => ""
    )

    @admin.should_receive(:set_valid_access_token)
    @admin.should_receive(:session_heartbeat!)

    @admin.login!("new_token")
    @admin.reload

    @admin.mobile_codes_sent.should == 0
    @admin.login_attempts.should == 0
    @admin.session_token.should_not be_blank
    @admin.session_access_token.should_not be_blank
  end
end
