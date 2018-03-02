class Api::EmailsController < Api::ApplicationController
  before_action :find_email, except: %i[index create]

  def index
    render json: site.emails.to_a, each_serializer: EmailSerializer
  end

  def show
    render json: @email
  end

  def create
    site.emails.create!(email_params)
    render json: @email
  end

  def update
    @email.update!(email_params)
    render json: @email
  end

  def destroy
    @email.destroy
    render json: { message: 'Email successfully deleted.' }
  end

  private

  def site
    @site ||= current_user.sites.find(params[:site_id])
  end

  def find_email
    @email = site.emails.find(params[:id])
  end

  def email_params
    params.require(:email).permit(:from_name, :from_email, :subject, :body)
  end
end
