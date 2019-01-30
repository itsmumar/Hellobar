class Api::EmailsController < Api::ApplicationController
  before_action :find_email, except: %i[create search]

  def show
    render json: @email
  end

  def create
    @email = site.emails.build(email_params)
    @email.save!

    render json: @email
  end

  def update
    @email.update!(email_params)
    render json: @email
  end

  def search
    results = site.emails.send(params[:email][:flag]).search(params[:email][:query])
    render json: results
  end

  private

  def site
    @site ||= current_user.sites.find(params[:site_id])
  end

  def find_email
    @email = site.emails.find(params[:id])
  end

  def email_params
    params.require(:email).permit(:from_name, :from_email, :subject, :body, :plain_body)
  end
end
