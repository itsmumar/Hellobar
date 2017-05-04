require 'static_script_assets'

module ThemeMacros
  def use_theme_fixtures
    StaticScriptAssets.env.append_path 'spec/fixtures/themes'

    before(:each) do
      @current_data = Theme.data
      Theme.data = [{
        name: 'Beige Test',
        id: 'beige-test',
        type: 'generic',
        directory: 'spec/fixtures/themes/beige'
      }, {
        name: 'Classic',
        id: 'classic',
        type: 'generic',
        default_theme: true,
        directory: 'spec/fixtures/themes/classic'
      }, {
        name: 'Traffic Growth',
        id: 'traffic-growth',
        type: 'template',
        element_types: ['Modal'],
        directory: 'lib/themes/templates/traffic-growth'
      }]
    end

    after(:each) do
      Theme.data = @current_data
    end
  end
end
