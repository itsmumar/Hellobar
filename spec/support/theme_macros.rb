module ThemeMacros
  def use_theme_fixtures
    before(:each) do
      @current_data = Theme.data
      Theme.data = [{
        name: "Beige Test",
        id: "beige-test",
        directory: Rails.root.join('spec', 'fixtures', 'themes', 'beige')
      },{
        name: "Classic",
        id: "classic",
        default_theme: true,
        directory: Rails.root.join('spec', 'fixtures', 'themes', 'classic')
      }]
    end

    after(:each) do
      Theme.data = @current_data
    end
  end
end
