class SettingsSerializer < ActiveModel::Serializer
  attributes :current_user, :geolocation_url, :track_editor_flow,
    :available_themes, :available_fonts, :country_codes

  def available_themes
    ActiveModel::ArraySerializer.new(themes_for_site, each_serializer: ThemeSerializer).as_json
  end

  def available_fonts
    ActiveModel::ArraySerializer.new(Font.all, each_serializer: FontSerializer).as_json
  end

  def current_user
    UserSerializer.new(user).as_json
  end

  def geolocation_url
    Settings.geolocation_url
  end

  def track_editor_flow
    user && user.sites.count == 1 && user.site_elements.count == 0
  end

  def country_codes
    I18n.t('country_codes')
  end

  private

  def user
    object
  end

  def themes_for_site
    if scope.capabilities.subtle_facet_theme?
      Theme.sorted
    else
      Theme.sorted.select { |theme| theme.id != 'subtle-facet' }
    end
  end
end
