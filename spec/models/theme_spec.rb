describe Theme do
  extend ThemeMacros
  use_theme_fixtures

  describe '.sorted' do
    it 'returns the default theme first' do
      expect(Theme.sorted.first.default_theme).to be_truthy
    end
  end
end
