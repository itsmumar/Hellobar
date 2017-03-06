class ContactSubmissionsController < ApplicationController
  before_action :authenticate_user!, except: [:new, :create]

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
    @site = current_user.sites.find_by(id: params[:site_id])

    email_params = {
      first_name: current_user.first_name,
      last_name: current_user.last_name,
      email: current_user.email,
      message: params[:message],
      preview: (params[:message] || '')[0, 50]
    }

    email_params[:website] = @site.url if @site

    MailerGateway.send_email('Contact Form', 'support@hellobar.com', email_params)
    flash[:success] = 'Your message has been sent!'

    redirect_to params[:return_to]
  end

  def new
    render layout: 'static'
  end

  def create
    raise ActionController::RoutingError, 'Not Found' unless params[:blank].blank? # Spam catcher

    email_params = params.require(:contact_submission).permit(:name, :email, :message)

    MailerGateway.send_email('Contact Form 2', 'support@hellobar.com', email_params)
    flash[:success] = 'Your message has been sent!'

    redirect_to new_contact_submission_path
  end
end
