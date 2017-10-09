class ContactSubmissionsController < ApplicationController
  before_action :authenticate_user!, except: %i[new create]

  include SitesHelper

  def email_developer
    site = current_user.sites.find(params[:site_id])
    if params[:developer_email].blank?
      flash[:error] = "Please enter your developer's email address."
    else
      developer_email = params[:developer_email].is_a?(Array) ? params[:developer_email].first : params[:developer_email]
      ContactFormMailer.contact_developer(developer_email, site, current_user).deliver_later
      flash[:success] = "We've sent the installation instructions to your developer!"
    end

    redirect_to site_path(site)
  end

  def generic_message
    site = current_user.sites.find_by(id: params[:site_id])
    ContactFormMailer.generic_message(params[:message], current_user, site).deliver_later
    flash[:success] = 'Your message has been sent!'

    redirect_to site ? site_path(site) : sites_path
  end

  def new
    render layout: 'static'
  end

  def create
    raise ActionController::RoutingError, 'Not Found' if params[:blank].present? # Spam catcher

    email_params = params.require(:contact_submission).permit(:name, :email, :message)

    ContactFormMailer.guest_message(**email_params.symbolize_keys).deliver_later

    flash[:success] = 'Your message has been sent!'
    redirect_to new_contact_submission_path
  end
end
