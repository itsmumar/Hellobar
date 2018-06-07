class PrivaciesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_site

  rescue_from ActiveRecord::RecordInvalid, with: :render_errors

  def edit
  end

  def update
    @site.assign_attributes site_params
    @site.save! context: :update_privacy
    @site.script.generate

    flash[:success] = 'Your settings have been updated.'
    redirect_to edit_site_privacy_path(@site)
  end

  private

  def site_params
    params
      .require(:site)
      .permit(:privacy_policy_url, :terms_and_conditions_url, :gdpr_consent_language, communication_types: [])
  end

  def render_errors(exception)
    flash.now[:error] = exception.record.errors.full_messages.to_sentence
    render :edit
  end
end
