module GonVariables
  extend ActiveSupport::Concern

  included do
    before_action :set_gon_variables
  end

  private

  def set_gon_variables
    set_lead_data
    set_country_codes
    set_settings
  end

  def set_lead_data
    return unless needs_filling_questionnaire?
    gon.lead_data = {
      industries: Lead::INDUSTRIES,
      job_roles: Lead::JOB_ROLES,
      challenges: Lead::CHALLENGES,
      company_sizes: Lead::COMPANY_SIZES,
      traffic_items: Lead::TRAFFIC_ITEMS
    }
  end

  def set_country_codes
    gon.countryCodes = I18n.t('country_codes')
  end

  def set_settings
    gon.settings = {
      geolocation_url: Hellobar::Settings[:geolocation_url]
    }
  end
end
