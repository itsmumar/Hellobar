class ContactSubmissionsController < ApplicationController
  before_action :authenticate_user!, except: %i[new create]

  include SitesHelper

  def email_developer
    @site = current_user.sites.find(params[:site_id])

    if params[:developer_email].blank?
      flash[:error] = "Please enter your developer's email address."
    else
      email_params = {
        site_url: @site.normalized_url,
        script_url: @site.script_url,
        user_email: current_user.email
      }
      developer_email = params[:developer_email].is_a?(Array) ? params[:developer_email].first : params[:developer_email]

      MailerGateway.send_email('Contact Developer 2', developer_email, email_params)
      flash[:success] = "We've sent the installation instructions to your developer!"
    end

    redirect_to site_path(@site)
  end

  def generic_message
    site = current_user.sites.find_by(id: params[:site_id])
    ContactFormMailer.generic_message(params[:message], current_user, site).delivery_later
    flash[:success] = 'Your message has been sent!'

    redirect_to params[:return_to]
  end

  def new
    render layout: 'static'
  end

  def create
    raise ActionController::RoutingError, 'Not Found' if params[:blank].present? # Spam catcher

    email_params = params.require(:contact_submission).permit(:name, :email, :message)

    ContactFormMailer.guest_message(email_params).delivery_later

    flash[:success] = 'Your message has been sent!'
    redirect_to new_contact_submission_path
  end
end
