require 'spec_helper'

describe Users::SessionsController do
  fixtures :all

  before(:each) do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "POST create" do
    it "logs in a user with valid params" do
      controller.current_user.should be_nil
      post :create, :user => {:email => "joey@polymathic.me", :password => "password"}
      controller.current_user.should == users(:joey)
    end

    it "should redirect if trying to sign in with an email that's in the wordpress database" do
      Hello::WordpressUser.should_receive(:email_exists?).with("user@website.com").and_return(true)

      post :create, :user => {:email => "user@website.com", :password => "asdfasdf"}

      response.should render_template("pages/redirect_login")
    end
  end
end
