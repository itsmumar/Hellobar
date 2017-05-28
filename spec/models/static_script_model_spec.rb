describe StaticScriptModel do
  let(:site) { create :site, :pro_managed, :with_rule }
  let(:options) { {} }
  let!(:model) { described_class.new(site, options) }

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
        no_b: site.capabilities.remove_branding?,
        b_variation: 'animated',
        preview: false,
        remove_branding: site_capabilities.remove_branding?,
        closable: site_capabilities.closable?,
        custom_targeted_bars: site_capabilities.custom_targeted_bars?,
        at_site_element_limit: site_capabilities.at_site_element_limit?,
        custom_thank_you_text: site_capabilities.custom_thank_you_text?,
        after_submit_redirect: site_capabilities.after_submit_redirect?,
        custom_html: site_capabilities.custom_html?,
        content_upgrades: site_capabilities.content_upgrades?,
        autofills: site_capabilities.autofills?,
        geolocation_injection: site_capabilities.geolocation_injection?,
        external_tracking: site_capabilities.external_tracking?,
        alert_bars: site_capabilities.alert_bars?
      }
      expect(capabilities).to match expected_capabilities
    end
  end

  describe '#pro_secret', :freeze do
    before do
      allow_any_instance_of(Array).to receive(:sample).and_return('d')
      allow(model).to receive(:rand).with(1_000_000).and_return(999)
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
      expect(StaticScriptAssets)
        .to receive(:render).with('container_common.css', site_id: site.id).and_return('container_common.css')

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
        .to eql "container_common.css\nbar/container.css\nmodal/container.css\nslider/container.css\n" \
                "takeover/container.css\ncustom/container.css\ncontentupgrade/container.css\nalert/container.css\n" \
                "hellobar-classic/container.css\nautodetect/container.css\nblue-autumn/container.css\n" \
                "blue-avalanche/container.css\nclassy/container.css\ndark-green-spring/container.css\n" \
                "evergreen-meadow/container.css\nfrench-rose/container.css\ngreen-timberline/container.css\n" \
                "marigold/container.css\ntraffic-growth/container.css\nviolet/container.css"
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
           question traffic_growth]
      end

      let(:bar_types) { %w[Bar Modal Slider Takeover Custom ContentUpgrade Alert] }
      let(:template_names) { %w[traffic_growth] }

      def all_templates
        bar_subtypes.flat_map { |subtype|
          bar_types.map do |type|
            if template_names.include?(subtype)
              element_types = Theme.find_by(id: subtype.tr('_', '-')).element_types
              "#{ type.downcase }_#{ subtype }" if element_types.include?(type)
            else
              "#{ type.downcase }_#{ subtype }"
            end
          end
        }.compact
      end

      before { allow(StaticScriptAssets).to receive(:render).and_return('') }

      context 'for all bar types except traffic_growth template' do
        let(:bar_subtypes_except_traffic_growth) { bar_subtypes - %w[traffic_growth] }
        let(:bars_number) { bar_subtypes_except_traffic_growth.count }

        it 'renders header and footer' do
          templates
          bar_types.map(&:downcase).each do |type|
            header_args = [type, 'header.html', site_id: site.id]
            footer_args = [type, 'footer.html', site_id: site.id]
            expect(StaticScriptAssets).to have_received(:render).with(*header_args).exactly(bars_number).times
            expect(StaticScriptAssets).to have_received(:render).with(*footer_args).exactly(bars_number).times
          end
        end

        context 'for all bar subtypes except Custom' do
          let(:bars_number) { (bar_types - %w[Custom]).count }

          it 'renders content markup' do
            templates
            bar_subtypes_except_traffic_growth.each do |subtype|
              args = ["#{ subtype.tr('/', '_') }.html", site_id: site.id]
              expect(StaticScriptAssets).to have_received(:render).with(*args).exactly(bars_number).times
            end
          end
        end
      end

      it 'renders traffic-growth/modal.html for traffic_growth template' do
        templates
        expect(StaticScriptAssets).to have_received(:render).with('traffic-growth', 'modal.html', site_id: site.id)
      end

      it 'returns array of template names and markups' do
        expect(names).to match_array all_templates
      end
    end

    context 'when templates not provided' do
      let!(:active_site_elements) { create :site_element, :slider, element_subtype: 'announcement', site: site }
      let(:markups) { model.templates.map { |template| template[:markup] } }
      let(:names) { model.templates.map { |template| template[:name] } }

      it 'returns array of template names and markups' do
        expect(markups.all?(&:present?)).to be_truthy
        expect(names).to match_array %w[slider_announcement]
      end
    end
  end

  describe '#branding_templates' do
    let(:templates) { model.branding_templates }
    let(:names) { templates.map { |template| template[:name] } }
    let(:markups) { templates.map { |template| template[:markup] } }

    before { allow(StaticScriptAssets).to receive(:render).and_wrap_original { |_, path| path.basename.sub_ext('').to_s } }

    it 'returns array of template names and markups' do
      expected = %w[branding_add_hb branding_animated branding_gethb branding_gethb_no_track
                    branding_not_using_hb branding_original branding_powered_by]

      expect(names).to match_array expected
      expect(markups).to match_array expected.map { |s| s.sub('branding_', '') }
    end
  end

  describe '#content_upgrade_template' do
    let(:templates) { model.content_upgrade_template }

    before { allow(StaticScriptAssets).to receive(:render).and_return('') }

    it 'returns array of template names and markups' do
      expect(templates).to match_array [{ name: 'contentupgrade', markup: '' }]
      expect(StaticScriptAssets).to have_received(:render).with('contentupgrade/contentupgrade.html', site_id: site.id)
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

  describe '#hb_backend_host' do
    let(:hb_backend_host) { 'hb_backend_host' }

    before do
      allow(Settings).to receive(:tracking_host).and_return hb_backend_host
    end

    it 'returns host' do
      expect(model.hb_backend_host).to eql hb_backend_host
    end
  end

  describe '#external_tracking' do
    context 'when site has external tracking capability' do
      let!(:site_elements) { create_list :site_element, 2, site: site }
      let(:external_events) { site_elements.flat_map { |se| create :site_element_external_events, site_element: se } }

      before do
        allow_any_instance_of(Site).to receive_message_chain(:capabilities, :external_tracking?).and_return(true)
      end

      it 'returns array of Google Analytics events' do
        expect(model.external_tracking).to match_array external_events
      end
    end

    context 'when site does not have external tracking capability' do
      let!(:site_elements) { create_list :site_element, 2, site: site }

      before do
        allow_any_instance_of(Site).to receive_message_chain(:capabilities, :external_tracking?).and_return(false)
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
        create(:condition, :url_is), create(:condition, :date_between), create(:condition, :time_before)
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
        expect(model.hellobar_element_css).to eql 'common.css'
      end
    end

    context 'with active elements' do
      before { allow(StaticScriptAssets).to receive(:render).and_wrap_original { |_, *path, **_options| path.join('/') } }
      before { allow(model).to receive(:element_types).and_return ['Bar'] }
      before { allow(model).to receive(:element_themes).and_return [Theme.find('autodetect')] }

      it 'returns common.css, element.css for each bar type and element.css for each theme' do
        expect(model.hellobar_element_css).to eql "common.css\nbar/element.css\nautodetect/element.css"
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
    let(:content_upgrade_styles) { generate :content_upgrade_styles }

    before do
      site.update_content_upgrade_styles! content_upgrade_styles
    end

    it 'returns site.settings[content_upgrades]' do
      expect(model.content_upgrades_styles).to eql content_upgrade_styles
    end
  end

  describe '#autofills' do
    let!(:autofill) { create :autofill, site: site }

    it 'returns autofills' do
      expect(model.autofills).to match_array site.autofills
    end
  end

  describe '#script_is_installed_properly' do
    context 'when test env' do
      specify { expect(model.script_is_installed_properly).to eql true }
    end

    context 'when not test env' do
      before { allow(Rails.env).to receive(:test?).and_return(false) }

      specify { expect(model.script_is_installed_properly).to eql 'scriptIsInstalledProperly()' }
    end
  end

  describe 'to_json' do
    let(:json) { JSON.parse(model.to_json, symbolize_names: true) }

    it 'renders models partial to json' do
      expect(json.keys).to match_array %i[
        preview_is_active version timestamp capabilities site_id site_url pro_secret
        hellobar_container_css templates branding_templates content_upgrade_template
        geolocation_url hb_backend_host site_write_key external_tracking hellobar_element_css
        content_upgrades content_upgrades_styles autofills script_is_installed_properly rules
      ]
    end

    describe 'image URLs' do
      let(:image) { create(:image_upload, :with_valid_image, site: site, version: version) }

      subject { json[:rules].first[:site_elements].first }

      context 'when there is a Modal site element' do
        let!(:element) { create(:modal_element, rule: site.rules.first, active_image: image) }

        context 'when image_upload version is 1' do
          let(:version) { 1 }

          it 'generates the correct image data' do
            expect(subject).to match(
              hash_including(
                image_style: 'modal',
                image_url: /original/,
                image_small_url: /original/,
                image_medium_url: /original/,
                image_large_url: /original/,
                image_modal_url: /original/
              )
            )
          end
        end

        context 'when image_upload version is 2' do
          let(:version) { 2 }

          it 'generates the correct image data' do
            expect(subject).to match(
              hash_including(
                image_style: 'modal',
                image_url: /modal/,
                image_small_url: /small/,
                image_medium_url: /medium/,
                image_large_url: /large/,
                image_modal_url: /modal/
              )
            )
          end
        end
      end

      context 'when there is a Takeover site element' do
        let!(:element) { create(:takeover_element, rule: site.rules.first, active_image: image) }

        context 'when image_upload version is 1' do
          let(:version) { 1 }

          it 'generates the correct image data' do
            expect(subject).to match(
              hash_including(
                image_style: 'large',
                image_url: /original/,
                image_small_url: /original/,
                image_medium_url: /original/,
                image_large_url: /original/,
                image_modal_url: /original/
              )
            )
          end
        end

        context 'when image_upload version is 2' do
          let(:version) { 2 }

          it 'generates the correct image data' do
            expect(subject).to match(
              hash_including(
                image_style: 'large',
                image_url: /modal/,
                image_small_url: /small/,
                image_medium_url: /medium/,
                image_large_url: /large/,
                image_modal_url: /modal/
              )
            )
          end
        end
      end
    end
  end
end
