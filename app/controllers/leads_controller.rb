class LeadsController < ApplicationController
  rescue_from ActiveRecord::RecordInvalid, with: :renders_json_error
  before_action :authenticate_user!

  def create
    current_user.create_lead!(lead_params)
    render nothing: true
  end

  private

  def renders_json_error(invalid)
    Raven.capture_exception(invalid)
    render json: invalid.record.errors.to_json, status: :unprocessable_entity
  end

  def lead_params
    params.require(:lead).permit(
      :industry, :job_role, :company_size, :estimated_monthly_traffic,
      :first_name, :last_name, :challenge,
      :challenge, :phone_number, :interested
    )
  end
end
