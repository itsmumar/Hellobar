class SettingsSerializer < ActiveModel::Serializer
  LEADS_CREATION_STARTING_DATE = Date.parse('2017-04-11').freeze

  attributes :current_user, :lead_data, :geolocation_url, :track_editor_flow, :available_themes, :available_fonts

  def available_themes
    ActiveModel::ArraySerializer.new(Theme.sorted, each_serializer: ThemeSerializer).as_json
  end

  def available_fonts
    ActiveModel::ArraySerializer.new(Font.all, each_serializer: FontSerializer).as_json
  end

  def current_user
    {
      current_user: UserSerializer.new(current_user).as_json,
      lead_data: lead_data,
      geolocation_url: Hellobar::Settings[:geolocation_url]
    }
  end

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

  def geolocation_url
    Hellobar::Settings[:geolocation_url]
  end

  def track_editor_flow
    current_user && current_user.sites.count == 1 && current_user.site_elements.count == 0
  end

  private

  def current_user
    object
  end

  def needs_filling_questionnaire?
    current_user && current_user.created_at >= LEADS_CREATION_STARTING_DATE && current_user.lead.blank?
  end
end
