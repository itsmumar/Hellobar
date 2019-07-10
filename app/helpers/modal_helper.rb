module ModalHelper
  def upgrade_modal_ab_class
    'upgrade-account-modal'
  end

  def rule_country_select name_value
    countries = I18n.t(:country_codes).map { |country| country.fetch_values :name, :code }
    select('rule', 'conditions_attributes', countries, { priority_countries: ['US'] }, disabled: 'disabled', id: nil, name: name_value, class: 'value location-country-select')
  end

  def day_select_options
    days = []
    Date::DAYNAMES.each_with_index { |x, i| days << [x, i] }
    days
  end
end
