describe SettingsSerializer do
  let!(:user) { create :user }
  let!(:site) { create :site, user: user }
  let(:serializer) { SettingsSerializer.new(user, scope: site) }

  describe '#available_themes' do
    let(:expected_themes) { Theme.sorted }
    let(:serialized_themes) { expected_themes.map { |theme| ThemeSerializer.new(theme).as_json } }

    context 'when site has got advanced_themes capability' do
      let(:site) { create :site, :pro_managed, user: user }

      it 'returns all themes' do
        expect(serializer.available_themes).to eql(serialized_themes)
      end
    end

    context 'when site has not got advanced_themes capability' do
      let(:site) { create :site, :pro, user: user }
      let(:advanced_themes) do
        %w[
          arctic-facet
          subtle-facet
          mall
          puesto
          tocaya
          gatsby
          gogo
          cocina
          tajima
          lionshare
          new
          resteo
          wooli
          pulse
          wayfarer
          rhythm
          chance
          sling
          marble
        ]
      end
      let(:expected_themes) { Theme.sorted.reject { |theme| theme.id.in? advanced_themes } }

      it 'does not return advanced themes' do
        expect(serializer.available_themes).to eql(serialized_themes)
      end
    end
  end

  describe '#available_fonts' do
    let(:serialized_fonts) { Font.all.map { |font| FontSerializer.new(font).as_json } }

    it 'returns all fonts' do
      expect(serializer.available_fonts).to eql(serialized_fonts)
    end
  end

  describe '#current_user' do
    it 'returns serialized user' do
      expect(serializer.current_user).to eql UserSerializer.new(user).as_json
    end
  end

  describe '#geolocation_url' do
    it 'returns Settings.geolocation_url' do
      expect(serializer.geolocation_url).to eql Settings.geolocation_url
    end
  end

  describe '#country_codes' do
    it 'returns country_codes from country_codes.en.yml' do
      expect(serializer.geolocation_url).to eql Settings.geolocation_url
    end
  end

  describe '#serializable_hash' do
    it 'has expected structure' do
      expect(serializer.serializable_hash).to include(
        :current_user, :geolocation_url,
        :available_themes, :available_fonts, :country_codes
      )
    end
  end
end
