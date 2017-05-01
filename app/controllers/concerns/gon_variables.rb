module GonVariables
  extend ActiveSupport::Concern

  included do
    before_action :set_gon_variables
  end

  private

  def set_gon_variables
    set_country_codes
    set_settings
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
