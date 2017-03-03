require 'spec_helper'

describe ContactSubmissionsController do
  fixtures :all

  describe "GET :new" do
    render_views
    it "works" do
      get :new
      expect(response).to be_success
      expect(response.body).to include("Send us feedback")
    end
  end

  describe "POST :create" do
    it "raises an error when the spam catcher field 'blank' is not blank" do
      expect{ post :create, {blank: "not blank", contact_submission: {email: "kaitlen@hellobar.com", name: "Kaitlen", message: "Hi Kaitlen"} }}.to raise_error(ActionController::RoutingError)
    end
  end

  describe "email_developer" do
    let!(:site) { sites(:zombo) }
    let!(:user) { stub_current_user(site.owners.first) }
    before do
      @email_params = {
        :site_url => "zombo.com",
        :script_url => site.script_url,
        :user_email => user.email
      }
    end

    it "sends an 'email your developer' message from email array" do
      dev_email_params = ["dev@polymathic.me"]

      MailerGateway.should_receive(:send_email).with("Contact Developer 2", "dev@polymathic.me", @email_params)
      post :email_developer, :developer_email => dev_email_params, :site_id => site.id
    end

    it "sends an 'email your developer' message from email string" do
      dev_email_params = "dev@polymathic.me"

      MailerGateway.should_receive(:send_email).with("Contact Developer 2", "dev@polymathic.me", @email_params)
      post :email_developer, :developer_email => dev_email_params, :site_id => site.id
    end
  end

  it "sends a generic message" do
    site = sites(:zombo)
    user = stub_current_user(site.owners.first)
    message = "HELP ME"
    return_to = root_path

    email_params = {
      :first_name => user.first_name,
      :last_name => user.last_name,
      :email => user.email,
      :message => message,
      :preview => message[0, 50],
      :website => site.url
    }

    MailerGateway.should_receive(:send_email).with("Contact Form", "support@hellobar.com", email_params)

    post :generic_message, :site_id => site.id, :message => message, :return_to => return_to

    response.should redirect_to(return_to)
  end

  it "generic message works without a site" do
    user = stub_current_user(users(:joey))
    message = "HELP ME"
    return_to = root_path

    email_params = {
      :first_name => user.first_name,
      :last_name => user.last_name,
      :email => user.email,
      :message => message,
      :preview => message[0, 50]
    }

    MailerGateway.should_receive(:send_email).with("Contact Form", "support@hellobar.com", email_params)

    post :generic_message, :message => message, :return_to => return_to

    response.should redirect_to(return_to)
  end
end
