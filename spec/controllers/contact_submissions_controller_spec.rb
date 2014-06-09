require 'spec_helper'

describe ContactSubmissionsController do
  fixtures :all

  it "sends a 'email your developer' message" do
    dev_email = "dev@polymathic.me"
    site = sites(:zombo)
    user = stub_current_user(site.owner)

    email_params = {
      :site_url => "zombo.com",
      :script_url => site.script_url,
      :user_email => user.email
    }

    MailerGateway.should_receive(:send_email).with("Contact Developer 2", dev_email, email_params)

    post :email_developer, :developer_email => dev_email, :site_id => site.id
  end

  it "sends a generic message" do
    site = sites(:zombo)
    user = stub_current_user(site.owner)
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
      :preview => message[0, 50],
    }

    MailerGateway.should_receive(:send_email).with("Contact Form", "support@hellobar.com", email_params)

    post :generic_message, :message => message, :return_to => return_to

    response.should redirect_to(return_to)
  end
end
