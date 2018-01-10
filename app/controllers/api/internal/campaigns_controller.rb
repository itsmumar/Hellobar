class Api::Internal::CampaignsController < Api::InternalController
  def update_status
    campaign.update(
      status: campaign_params[:status],
      sent_at: Time.current
    )

    head :ok
  end

  private

  def campaign_params
    params.require(:campaign).permit :status
  end

  def campaign
    @campaign ||= Campaign.find params[:id]
  end
end
