module ThemeMacros
  def use_theme_fixtures
    ScriptGenerator.assets.append_path 'spec/fixtures/themes'

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
      }]
    end

    after(:each) do
      Theme.data = @current_data
    end
  end
end
