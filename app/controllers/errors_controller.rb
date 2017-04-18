class ErrorsController < ApplicationController
  layout 'error'

  # required for handling not-found GET *.js requests
  skip_before_action :verify_authenticity_token

  respond_to :html, :js, :css, :json, :text

  def show
    respond_to do |format|
      format.html { render code.to_s, status: code }
      format.js { head code }
      format.css { head code }
      format.json { render json: Hash[error: code.to_s], status: code }
      format.text { render text: "Error: #{ code }", status: code }
    end
  end

  protected

  def code
    params[:code] || 500
  end
end
