require 'spec_helper'

describe Users::SessionsController do
  fixtures :all

  before(:each) do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @wordpress_user = OpenStruct.new(id: 123)
  end

  describe "POST create" do
    it "logs in a user with valid params" do
      controller.current_user.should be_nil
      post :create, :user => {:email => "joey@polymathic.me", :password => "password"}
      controller.current_user.should == users(:joey)
    end

    it "redirects oauth users to their respective oauth path" do
      users(:joey).authentications.create(provider: "google_oauth2", uid: "123")
      post :create, :user => {:email => "joey@polymathic.me", :password => "some incorrect pass"}
      response.should redirect_to(user_omniauth_authorize_path("google_oauth2"))
    end

    it "redirects 1.0 users to migration wizard if the correct password is used" do
      pending "until migration wizard is made available to all users"

      email, password = "user@website.com", "asdfasdf"

      Hello::WordpressUser.should_receive(:email_exists?).with(email).and_return(true)
      Hello::WordpressUser.should_receive(:authenticate).with(email, password).and_return(@wordpress_user)

      post :create, :user => {:email => email, :password => password}

      response.should redirect_to(new_user_migration_path)
    end

    it "asks 1.0 users to reauthenticate if their password is wrong" do
      pending "until migration wizard is made available to all users"

      email, password = "user@website.com", "asdfasdf"

      Hello::WordpressUser.should_receive(:email_exists?).with(email).and_return(true)
      Hello::WordpressUser.should_receive(:authenticate).with(email, password).and_return(nil)

      post :create, :user => {:email => email, :password => password}

      flash.now[:alert].should =~ /Invalid/
      response.should render_template("users/sessions/new")
    end
  end
end
