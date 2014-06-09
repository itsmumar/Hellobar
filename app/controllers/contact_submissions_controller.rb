class ContactSubmissionsController < ApplicationController
  before_filter :authenticate_user!
  include SitesHelper

  def email_developer
    @site = current_user.sites.find(params[:site_id])

    if params[:developer_email].blank?
      flash[:error] = "Please enter your developer's email address."
    else
      email_params = {
        :site_url => display_url_for_site(@site),
        :script_url => @site.script_url,
        :user_email => current_user.email
      }

      MailerGateway.send_email("Contact Developer 2", params[:developer_email], email_params)
      flash[:success] = "We've sent the installation instructions to your developer!"
    end

    redirect_to site_path(@site)
  end
end
