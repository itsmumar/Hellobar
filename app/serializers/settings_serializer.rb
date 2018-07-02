class SettingsSerializer < ActiveModel::Serializer
  attributes :current_user, :geolocation_url,
    :available_themes, :available_fonts, :country_codes

  def available_themes
    themes_for_site.map { |theme| ThemeSerializer.new(theme).as_json }
  end

  def available_fonts
    Font.all.map { |font| FontSerializer.new(font).as_json }
  end

  def current_user
    UserSerializer.new(user).as_json
  end

  def geolocation_url
    Settings.geolocation_url
  end

  def country_codes
    I18n.t('country_codes')
  end

  private

  def user
    object
  end

  def themes_for_site
    if scope.capabilities.advanced_themes?
      Theme.sorted
    else
      Theme.sorted.reject(&:advanced?)
    end
  end
end
