class Api::SettingsController < ApplicationController
  before_action :authenticate_user!

  def index
    render json: {
      current_user: UserSerializer.new(current_user).as_json,
      lead_data: lead_data,
      geolocation_url: Hellobar::Settings[:geolocation_url]
    }
  end

  private

  def lead_data
    return unless needs_filling_questionnaire?

    {
      industries: Lead::INDUSTRIES,
      job_roles: Lead::JOB_ROLES,
      challenges: Lead::CHALLENGES,
      company_sizes: Lead::COMPANY_SIZES,
      traffic_items: Lead::TRAFFIC_ITEMS,
      country_codes: I18n.t('country_codes')
    }
  end
end
