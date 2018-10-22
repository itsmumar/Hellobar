describe StaticScriptModel do
  let(:site) { create :site, :pro_managed, :with_rule }
  let(:options) { {} }
  let!(:model) { described_class.new(site, options) }

  before do
    allow_any_instance_of(SiteElement)
      .to receive(:statistics).and_return(SiteStatistics.new)
  end

  describe '#preview_is_active' do
    let(:options) { { preview: true } }

    it 'returns options[:preview]' do
      expect(model.preview_is_active).to eql true
    end
  end

  describe '#version' do
    before { allow(GitUtils).to receive(:current_commit).and_return('3237d629a2d511725515660d5f0a316fcb81f136') }

    it 'returns git commit hash' do
      expect(model.version).to eql '3237d629a2d511725515660d5f0a316fcb81f136'
    end
  end

  describe '#timestamp', :freeze do
    it 'returns current time' do
      expect(model.timestamp).to eql Time.current
    end
  end

  describe '#capabilities' do
    let(:capabilities) { model.capabilities }
    let(:site_capabilities) { build :site_capabilities }

    before { allow(site).to receive(:capabilities).and_return(site_capabilities) }

    it 'returns a Hash with capabilities' do
      expected_capabilities = {
        autofills: site_capabilities.autofills?,
        geolocation_injection: site_capabilities.geolocation_injection?,
        external_tracking: site_capabilities.external_tracking?
      }
      expect(capabilities).to match expected_capabilities
    end
  end

  describe '#pro_secret', :freeze do
    before do
      allow_any_instance_of(Array).to receive(:sample).and_return('d')
      allow(model).to receive(:rand).with(1_000_000).and_return(999)
      allow(Rails.env).to receive(:test?).and_return(false)
    end

    it 'returns random token based on site url and id' do
      token = Digest::SHA1.hexdigest("999#{ site.url.to_s.upcase }#{ site.id }#{ Time.current.to_f }999")
      expect(model.pro_secret).to eql "d#{ token }"
    end
  end

  describe '#site_timezone' do
    it 'returns formatted zone offest' do
      site.timezone = 'Asia/Jakarta'
      expect(model.site_timezone).to eql Time.find_zone!(site.timezone).formatted_offset
    end

    context 'when timezone is nil' do
      before { site.timezone = nil }

      it 'returns nil' do
        expect(model.site_timezone).to be_nil
      end
    end
  end

  describe '#hellobar_container_css' do
    before do
      allow(model).to receive(:element_types).and_return SiteElement.types
      allow(model).to receive(:element_themes).and_return Theme.sorted
    end

    it 'returns css for all kind of containers' do
      SiteElement.types.each do |type|
        type = type.downcase
        expect(StaticScriptAssets)
          .to receive(:render).with(type, 'container.css', site_id: site.id).and_return("#{ type }/container.css")
      end

      Theme.all.each do |theme|
        expect(StaticScriptAssets)
          .to receive(:render).with(theme.container_css_path, site_id: site.id).and_return(theme.container_css_path)
      end

      expect(model.hellobar_container_css)
        .to eql %w[
          bar/container.css
          modal/container.css
          slider/container.css
          takeover/container.css
          alert/container.css
          hellobar-classic/container.css
          model-new/container.css
          arctic-facet/container.css
          autodetect/container.css
          blue-autumn/container.css
          blue-avalanche/container.css
          classy/container.css
          cocina/container.css
          dark-green-spring/container.css
          evergreen-meadow/container.css
          french-rose/container.css
          gogo/container.css
          green-timberline/container.css
          lionshare/container.css
          mall/container.css
          marigold/container.css
          puesto/container.css
          pulse/container.css
          resteo/container.css
          sling/container.css
          smooth-impact/container.css
          subtle-facet/container.css
          tajima/container.css
          tocaya/container.css
          violet/container.css
          wayfarer/container.css
          wooli/container.css
        ].join("\n")
    end
  end

  describe '#templates' do
    context 'when templates provided via options' do
      let(:options) { { templates: SiteElement.all_templates } }
      let(:templates) { model.templates }
      let(:names) { templates.map { |template| template[:name] } }

      let(:bar_subtypes) do
        %w[call traffic email announcement
           social/tweet_on_twitter social/follow_on_twitter social/like_on_facebook social/plus_one_on_google_plus
           social/pin_on_pinterest social/follow_on_pinterest social/share_on_buffer social/share_on_linkedin
           question]
      end

      let(:bar_types) { %w[Bar Modal Slider Takeover Alert] }

      def all_templates
        bar_subtypes.flat_map { |subtype|
          bar_types.map { |type| "#{ type.downcase }_#{ subtype }" }
        }.compact
      end

      before { allow(StaticScriptAssets).to receive(:render).and_return('') }

      context 'for all bar types' do
        let(:bars_number) { bar_subtypes.count }

        it 'renders header and footer' do
          templates

          bar_types.map(&:downcase).each do |type|
            header_args = [type, 'header.html', site_id: site.id]
            footer_args = [type, 'footer.html', site_id: site.id]
            expect(StaticScriptAssets).to have_received(:render).with(*header_args).exactly(bars_number).times
            expect(StaticScriptAssets).to have_received(:render).with(*footer_args).exactly(bars_number).times
          end
        end

        context 'for all bar subtypes' do
          let(:bars_number) { bar_types.count }

          it 'renders content markup' do
            templates

            bar_subtypes.each do |subtype|
              args = ["#{ subtype.tr('/', '_') }.html", site_id: site.id]
              expect(StaticScriptAssets).to have_received(:render).with(*args).exactly(bars_number).times
            end
          end
        end
      end

      it 'returns array of template names and markups' do
        expect(names).to match_array all_templates
      end
    end

    context 'when templates not provided' do
      let!(:active_site_elements) { create :site_element, element_subtype: 'announcement', site: site }
      let(:markups) { model.templates.map { |template| template[:markup] } }
      let(:names) { model.templates.map { |template| template[:name] } }

      it 'returns array of template names and markups' do
        expect(markups.all?(&:present?)).to be_truthy
        expect(names).to match_array %w[bar_announcement]
      end
    end
  end

  describe '#geolocation_url' do
    let(:geolocation_url) { 'geolocation_url' }

    before do
      allow(Settings).to receive(:geolocation_url).and_return geolocation_url
    end

    it 'returns url' do
      expect(model.geolocation_url).to eql geolocation_url
    end
  end

  describe '#external_tracking' do
    context 'when site has external tracking capability' do
      let!(:alert) { create(:alert, site: site) }
      let!(:slider) { create(:slider, site: site) }
      let(:alert_events) { create :site_element_external_events, site_element: alert }
      let(:slider_events) { create :site_element_external_events, site_element: slider }
      let(:site_elements) { [alert, slider] }
      let(:external_events) { alert_events + slider_events }

      before do
        allow_any_instance_of(Site)
          .to receive_message_chain(:capabilities, :external_tracking?)
          .and_return(true)
      end

      it 'returns array of Google Analytics events' do
        expect(model.external_tracking).to match_array external_events
      end
    end

    context 'when site does not have external tracking capability' do
      let!(:site_elements) { create_list :site_element, 2, site: site }

      before do
        allow_any_instance_of(Site)
          .to receive_message_chain(:capabilities, :external_tracking?)
          .and_return(false)
      end

      it 'returns empty array' do
        expect(model.external_tracking).to eql []
      end
    end
  end

  describe '#rules' do
    let!(:site_element) { create :site_element, site: site }
    let(:rules) { create_list :static_script_rule, 1, rule: site.rules.first }

    before do
      site.rules.first.update conditions: [
        create(:condition, :url_path), create(:condition, :date_between), create(:condition, :time_before)
      ]
    end

    it 'returns array of match, conditions and site_elements' do
      expect(model.rules).to match_array rules
    end

    context 'with options[:no_rules]' do
      let!(:options) { { no_rules: true } }

      it 'returns empty array' do
        expect(model.rules).to match_array []
      end
    end
  end

  describe '#hellobar_element_css' do
    context 'without active elements' do
      before { allow(StaticScriptAssets).to receive(:render).and_wrap_original { |_, filename| filename } }

      it 'returns common.css' do
        expect(model.hellobar_element_css).to eql ''
      end
    end

    context 'with active elements' do
      before { allow(StaticScriptAssets).to receive(:render).and_wrap_original { |_, *path, **_options| path.join('/') } }
      before { allow(model).to receive(:element_types).and_return ['Bar'] }
      before { allow(model).to receive(:element_themes).and_return [Theme.find('autodetect')] }

      it 'returns element.css for each bar type and element.css for each theme' do
        expect(model.hellobar_element_css).to eql "bar/element.css\nautodetect/element.css"
      end
    end
  end

  describe '#content_upgrades' do
    let!(:content_upgrades) { create_list :content_upgrade, 2, site: site }
    let!(:content_upgrades_hash) do
      content_upgrades.inject({}) do |hash, content_upgrade|
        hash.update create(:static_script_content_upgrade, content_upgrade: content_upgrade)
      end
    end

    it 'returns content_upgrades' do
      expect(model.content_upgrades).to eql content_upgrades_hash
    end
  end

  describe '#content_upgrade_styles' do
    let(:content_upgrade_styles) { attributes_for(:content_upgrade_styles) }
    let(:font_family) { ContentUpgradeStyles::AVAILABLE_FONTS[content_upgrade_styles[:offer_font_family_name]] }

    before do
      site.content_upgrade_styles.update!(content_upgrade_styles)
    end

    it 'returns styles attributes and font_family' do
      expect(model.content_upgrades_styles).to include(content_upgrade_styles.stringify_keys)
    end

    it 'returns offer_font_family' do
      expect(model.content_upgrades_styles).to include('offer_font_family' => font_family)
    end
  end

  describe '#autofills' do
    let!(:autofill) { create :autofill, site: site }

    it 'returns autofills' do
      expect(model.autofills).to match_array site.autofills
    end
  end

  describe 'to_json' do
    let(:json) { JSON.parse(model.to_json).deep_symbolize_keys }

    it 'renders models partial to json' do
      expect(json.keys).to match_array %i[
        preview_is_active version modules_version timestamp capabilities site_id
        site_url pro_secret hellobar_container_css templates geolocation_url
        tracking_url site_write_key external_tracking hellobar_element_css
        content_upgrades content_upgrades_styles autofills rules
        disable_self_check gdpr_enabled gdpr_consent gdpr_agreement gdpr_action
      ]
    end

    context 'with custom fonts' do
      let(:headline) { '<span style="font-family: HeadlineFont, sans-serif;">text</span>' }
      let!(:element) { create(:site_element, site: site, headline: headline) }

      it 'includes fonts' do
        expect(json.dig(:rules, 0, :site_elements, 0)).to include fonts: ['HeadlineFont']
      end
    end

    describe 'image URLs' do
      let(:image) { create(:image_upload, :with_valid_image, site: site) }

      let(:site_element) { json[:rules].first[:site_elements].first }

      context 'when there is a Modal site element' do
        let!(:element) { create(:modal, rule: site.rules.first, active_image: image) }

        it 'generates the correct image data' do
          expect(site_element).to match(
            hash_including(
              image_style: 'modal',
              image_url: /modal/,
              image_large_url: /large/,
              image_modal_url: /modal/
            )
          )
        end
      end

      context 'when there is a Takeover site element' do
        let!(:element) { create(:takeover, rule: site.rules.first, active_image: image) }

        it 'generates the correct image data' do
          expect(site_element).to match(
            hash_including(
              image_style: 'large',
              image_url: /modal/,
              image_large_url: /large/,
              image_modal_url: /modal/
            )
          )
        end
      end
    end
  end

  describe '#gdpr_enabled' do
    it 'returns site.gdpr_enabled?' do
      expect(model.gdpr_enabled).to be site.gdpr_enabled?
    end
  end

  describe '#gdpr_consent' do
    let(:site) do
      create :site,
        communication_types: %w[newsletter promotional partnership product research]
    end

    it 'returns consent sentence' do
      expect(model.gdpr_consent)
        .to eql 'I consent to occasionally receive newsletter, promotional, ' \
                'partnership, product/service, and market research emails.'
    end
  end

  describe '#gdpr_agreement' do
    let(:site) do
      create(:site, privacy_policy_url: 'http://mysite.com/privacy', terms_and_conditions_url: 'http://mysite.com/terms')
    end

    it 'returns agreement HTML' do
      expect(model.gdpr_agreement)
        .to eql 'I have read and agree to the ' \
                '<a target="_blank" href="http://mysite.com/privacy">Privacy Policy</a> and ' \
                '<a target="_blank" href="http://mysite.com/terms">Terms and Conditions</a>.'
    end
  end

  describe '#gdpr_action' do
    it 'returns action text' do
      expect(model.gdpr_action).to eql 'Submit'
    end
  end

  describe '#disable_self_check' do
    before { allow(Rails.env).to receive(:production?).and_return true }

    context 'when preview' do
      let(:options) { { preview: true } }

      it 'returns true' do
        expect(model.disable_self_check).to be_truthy
      end
    end

    context 'when site url is mysite.com' do
      let(:site) { create :site, url: 'http://mysite.com' }

      it 'returns true' do
        expect(model.disable_self_check).to be_truthy
      end
    end

    context 'when site has disable_script_self_check capabilities' do
      let(:site) { create :site, :pro_managed }

      it 'returns true' do
        expect(model.disable_self_check).to be_truthy
      end
    end

    context 'when Rails.env is not production || edge || staging' do
      let(:site) { create :site }

      before { allow(Rails.env).to receive(:production?).and_return false }
      before { allow(Rails.env).to receive(:edge?).and_return false }
      before { allow(Rails.env).to receive(:staging?).and_return false }

      it 'returns true' do
        expect(model.disable_self_check).to be_truthy
      end
    end
  end
end
