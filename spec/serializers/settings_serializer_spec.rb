describe SettingsSerializer do
  let!(:user) { create :user }
  let!(:site) { create :site, user: user }
  let(:serializer) { SettingsSerializer.new(user, scope: site) }

  describe '#available_themes' do
    context 'when site has got advanced_themes capability' do
      let(:site) { create :site, :pro_managed, user: user }

      it 'returns all themes' do
        expect(serializer.available_themes)
          .to eql ActiveModel::ArraySerializer.new(Theme.sorted, each_serializer: ThemeSerializer).as_json
      end
    end

    context 'when site has not got advanced_themes capability' do
      let(:site) { create :site, :pro, user: user }
      let(:advanced_themes) { %w[subtle-facet smooth-impact] }

      it 'does not return advanced themes' do
        themes = Theme.sorted.reject { |theme| theme.id.in? advanced_themes }

        expect(serializer.available_themes)
          .to eql ActiveModel::ArraySerializer.new(themes, each_serializer: ThemeSerializer).as_json
      end
    end
  end

  describe '#available_fonts' do
    it 'returns all fonts' do
      expect(serializer.available_fonts)
        .to eql ActiveModel::ArraySerializer.new(Font.all, each_serializer: FontSerializer).as_json
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

  describe '#track_editor_flow' do
    context 'when user has a site but has no bars yet' do
      it 'returns true' do
        expect(serializer.track_editor_flow).to be_truthy
      end
    end

    context 'when user has a site but has no bars yet' do
      let!(:site) { create :site, :with_rule }

      before { create :site_element, site: site }

      it 'returns false' do
        expect(serializer.track_editor_flow).to be_falsey
      end
    end
  end

  describe '#serializable_hash' do
    it 'has expected structure' do
      expect(serializer.serializable_hash).to include(
        :current_user, :geolocation_url, :track_editor_flow,
        :available_themes, :available_fonts, :country_codes
      )
    end
  end
end
