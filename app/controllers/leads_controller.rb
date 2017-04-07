class LeadsController < ApplicationController
  before_action :authenticate_user!

  def create
    current_user.lead.update!(lead_params)
    render nothing: true
  end

  private

  def lead_params
    params.require(:lead).permit(
      :industry, :job_role, :company_size, :estimated_monthly_traffic,
      :first_name, :last_name, :challenge,
      :challenge, :phone_number, :interesting
    )
  end
end
