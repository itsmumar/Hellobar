class ExitIntentController < ApplicationController
  before_action :authenticate_user!

  def update
    user = User.find(params[:user_id])
    user.update_attributes(exit_intent_modal_last_shown_at: Time.zone.now)
    respond_to do |format|
      format.js { render nothing: true }
    end
  end
end
