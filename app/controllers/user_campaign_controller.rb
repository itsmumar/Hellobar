class UserCampaignController < ApplicationController
  before_action :authenticate_user!
  before_action :find_user

  def update_exit_intent
    @user.update_attributes(exit_intent_modal_last_shown_at: Time.zone.now)
    render nothing: true
  end

  def update_upgrade_suggest
    @user.update_attributes(upgrade_suggest_modal_last_shown_at: Time.zone.now)
    render nothing: true
  end

  private

  def find_user
    @user = User.find(params[:user_id])
  end
end
