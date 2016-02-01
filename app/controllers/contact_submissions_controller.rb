class ContactSubmissionsController < ApplicationController
  before_action :authenticate_user!

  include SitesHelper

  def email_developer
    @site = current_user.sites.find(params[:site_id])

    if params[:developer_email].blank?
      flash[:error] = "Please enter your developer's email address."
    else
      email_params = {
        :site_url => @site.normalized_url,
        :script_url => @site.script_url,
        :user_email => current_user.email
      }

      MailerGateway.send_email("Contact Developer 2", params[:developer_email], email_params)
      flash[:success] = "We've sent the installation instructions to your developer!"
    end

    redirect_to site_path(@site)
  end

  def generic_message
    @site = current_user.sites.find_by_id(params[:site_id])

    email_params = {
      :first_name => current_user.first_name,
      :last_name => current_user.last_name,
      :email => current_user.email,
      :message => params[:message],
      :preview => (params[:message] || "")[0, 50]
    }

    email_params.merge!(:website => @site.url) if @site

    MailerGateway.send_email("Contact Form", "support@hellobar.com", email_params)
    flash[:success] = "Your message has been sent!"

    redirect_to params[:return_to]
  end
end
