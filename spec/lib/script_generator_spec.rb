require 'spec_helper'

describe ScriptGenerator do
  extend ThemeMacros

  before do
    allow(Hello::DataAPI).to receive(:lifetime_totals).and_return(nil)
  end

  describe '#render' do
    let(:site) { create(:site, :with_user, :pro, elements: %i(traffic email facebook twitter)) }
    let(:generator) { ScriptGenerator.new(site) }

    it 'renders the site id variable' do
      expected_string = "HB_SITE_ID = #{ site.id };"

      expect(generator.render).to include(expected_string)
    end

    it 'renders the backend host variable' do
      original_setting = Hellobar::Settings[:tracking_host]
      Hellobar::Settings[:tracking_host] = 'hi-there.hellobar.com'
      expected_string = 'HB_BACKEND_HOST = "hi-there.hellobar.com";'

      expect(generator.render).to include(expected_string)
      Hellobar::Settings[:tracking_host] = original_setting
    end

    it 'renders the HB_TZ timezone variable' do
      allow(site).to receive(:timezone).and_return('America/Chicago')
      Time.zone = 'America/Chicago'
      expected_string = "HB_TZ = \"#{ Time.zone.now.formatted_offset }\";"

      expect(generator.render).to include(expected_string)
    end

    it 'includes the minified hellobar css' do
      allow(generator).to receive :hellobar_container_css
      hellobar_css = ScriptGenerator.assets['common.css'].to_s
      element_css = ScriptGenerator.assets['bar/element.css'].to_s

      allow(CSSMin).to receive(:minify) { |x| x }
      result = generator.render

      expect(hellobar_css).not_to be_empty
      expect(element_css).not_to be_empty
      expect(result).to include hellobar_css.to_json[1..-2]
      expect(result).to include element_css.to_json[1..-2]
    end

    it 'includes the hellobar container css' do
      allow(generator).to receive :hellobar_element_css
      allow(generator).to receive(:pro_secret) { 'random' }
      container_css = ScriptGenerator.assets['container_common.css'].to_s
      container_css.gsub!('hellobar-container', 'random-container')
      element_container_css = ScriptGenerator.assets['bar/container.css'].to_s
      element_container_css.gsub!('hellobar-container', 'random-container')

      allow(CSSMin).to receive(:minify) { |x| x }
      result = generator.render

      expect(container_css).not_to be_empty
      expect(element_container_css).not_to be_empty
      expect(result).to include container_css.to_json[1..-2]
      expect(result).to include element_container_css.to_json[1..-2]
    end

    it 'renders the initialization of the hellobar queue object' do
      hbq_initialization = '_hbq = new HBQ();'

      expect(generator.render).to include(hbq_initialization)
    end

    context 'when templates are present' do
      it 'renders the setTemplate function on HB with the template name and markup' do
        template = { name: 'yey name', markup: 'yey markup' }
        allow(generator).to receive(:templates).and_return([template])
        allow(generator).to receive(:hellobar_container_css)
        allow(generator).to receive(:hellobar_element_css)

        expected_string = 'HB.setTemplate("yey name", yey markup);'

        expect(generator.render).to include(expected_string)
      end

      it 'renders only the setTemplate definition and 1 call per bar type' do
        bar = Bar.new(element_subtype: 'traffic', theme_id: 'classic')
        allow(site).to receive(:site_elements).and_return(double('site_elements', active: [bar, bar], active_content_upgrades: [], none?: true))

        generator = ScriptGenerator.new site

        expect(generator.render.scan('setTemplate').size).to eq(2)
      end

      it 'renders the setTemplate definition and 1 call per bar type for multiple types' do
        traffic_bar = Bar.new(element_subtype: 'traffic', theme_id: 'classic')
        email_bar = Bar.new(element_subtype: 'email', theme_id: 'classic')
        allow(site).to receive(:site_elements).and_return(double('site_elements', active: [traffic_bar, email_bar], active_content_upgrades: [], none?: true))

        generator = ScriptGenerator.new site

        expect(generator.render.scan('setTemplate').size).to eq(3)
      end
    end

    context 'when rules are present' do
      let(:rule) { Rule.new }

      it 'has a start date constraint when present' do
        condition = Condition.new value: { 'start_date' => Date.new(2000, 01, 01) }, operand: Condition::OPERANDS[:after], segment: 'DateCondition'
        allow(rule).to receive(:conditions).and_return([condition])
        allow(site).to receive(:rules).and_return([rule])

        expected_string = 'HB.addRule("", [{"segment":"dt","operand":"is after","value":{"start_date":"2000-01-01"}}], [])'

        expect(generator.render).to include(expected_string)
      end

      it 'does NOT have a start date constraint when not present' do
        allow(site).to receive(:rules).and_return([rule])

        expected_string = 'HB.addRule("", [], [])}'

        expect(generator.render).to include(expected_string)
      end

      it 'has an end date constraint when present' do
        condition = Condition.new value: { 'end_date' => Date.new(2015, 01, 01) }, operand: Condition::OPERANDS[:before], segment: 'DateCondition'
        allow(rule).to receive(:conditions).and_return([condition])
        allow(site).to receive(:rules).and_return([rule])

        expected_string = 'HB.addRule("", [{"segment":"dt","operand":"is before","value":{"end_date":"2015-01-01"}}], [])}'

        expect(generator.render).to include(expected_string)
      end

      it 'does NOT have a start date constraint when not present' do
        allow(site).to receive(:rules).and_return([rule])

        expected_string = 'HB.addRule("", [], [])}'

        expect(generator.render).to include(expected_string)
      end

      it 'adds an exlusion constraint for all blacklisted URLs' do
        conditions = [Condition.new(value: '/signup', operand: :does_not_include, segment: 'UrlCondition')]
        allow(rule).to receive(:site_elements).and_return(double('site_elements', active: []))
        allow(rule).to receive(:attributes).and_return({})
        allow(rule).to receive(:conditions).and_return(conditions)
        allow(site).to receive(:rules).and_return([rule])

        expected_string = 'HB.addRule("", [{"segment":"pu","operand":"does_not_include","value":"/signup"}], [])'

        expect(generator.render).to include(expected_string)
      end

      it 'converts does_not_include urls to paths' do
        conditions = [Condition.new(value: 'http://soamazing.com/signup', operand: :does_not_include, segment: 'UrlCondition')]
        allow(rule).to receive(:site_elements).and_return(double('site_elements', active: []))
        allow(rule).to receive(:attributes).and_return({})
        allow(rule).to receive(:conditions).and_return(conditions)
        allow(site).to receive(:rules).and_return([rule])

        expected_string = 'HB.addRule("", [{"segment":"pu","operand":"does_not_include","value":"http://soamazing.com/signup"}], [])}'

        expect(generator.render).to include(expected_string)
      end

      it 'does NOT have exclusion constraints when no sites are blacklisted' do
        allow(site).to receive(:rules).and_return([rule])

        expected_string = /HB.umatch(.*)/

        expect(generator.render).not_to match(expected_string)
      end

      it 'adds an inclusion constraint for all whitelisted URLs' do
        conditions = [Condition.new(value: '/signup', operand: Condition::OPERANDS[:includes], segment: 'UrlCondition')]
        allow(rule).to receive(:conditions).and_return(conditions)
        allow(site).to receive(:rules).and_return([rule])

        expected_string = 'HB.addRule("", [{"segment":"pu","operand":"includes","value":"/signup"}], [])'

        expect(generator.render).to include(expected_string)
      end

      it 'does NOT have inclusion constraints when no sites are whitelisted' do
        allow(generator).to receive(:rules).and_return([rule])

        expected_string = /HB.umatch(.*)/

        expect(generator.render).not_to match(expected_string)
      end

      it 'does NOT include nil values' do
        site_element = build(:site_element, :bar, custom_js: '', custom_css: nil)
        site_elements = [site_element]
        allow(site).to receive(:rules).and_return([rule])
        allow(site_elements).to receive(:active).and_return(site_elements)
        allow(rule).to receive(:site_elements).and_return(site_elements)

        expect(generator.rules.first[:site_elements]).to include 'custom_js'
        expect(generator.rules.first[:site_elements]).not_to include 'custom_css'
      end

      it 'includes false values' do
        site_element = build(:site_element, :bar)
        site_elements = [site_element]
        allow(site).to receive(:rules).and_return([rule])
        allow(site_elements).to receive(:active).and_return(site_elements)
        allow(rule).to receive(:site_elements).and_return(site_elements)
        allow(site_element).to receive(:email_redirect?).and_return(false)

        expect(generator.rules.first[:site_elements]).to include '"email_redirect":false'
      end
    end

    context 'site element has a theme' do
      use_theme_fixtures
      before do
        create(:site_element, rule: site.rules.last, theme_id: 'beige-test')
      end

      it 'includes the container theme css' do
        expected_string = '#beige-container{border:1px}'

        expect(generator.render).to include(expected_string)
      end

      it 'includes the element theme css' do
        expected_string = '#beige-element{border:1px}'

        expect(generator.render).to include(expected_string)
      end
    end

    context 'site element does not have a theme' do
      use_theme_fixtures

      it 'does not includes the container theme css' do
        expected_string = '#beige-container{border:1px}'

        expect(generator.render).to_not include(expected_string)
      end

      it 'does not include the element theme css' do
        expected_string = '#beige-element{border:1px}'
        expect(generator.render).to_not include(expected_string)
      end
    end

    context 'modal with traffic-growth template' do
      use_theme_fixtures

      before do
        site.rules.last.site_elements << create(:modal_element, theme_id: 'traffic-growth')
      end

      it 'renders successfully' do
        expect(generator.render).to include('traffic-growth')
      end
    end
  end

  describe '#rules' do
    let(:site) { create(:site, :with_user, :pro) }
    let(:contact_list) { create(:contact_list, site: site) }
    let(:generator) { ScriptGenerator.new(site) }
    let(:rule) { create(:rule, match: nil) }

    it 'returns the proper array of hashes for a sites rules' do
      rule = Rule.new id: 1
      allow(site).to receive(:rules).and_return([rule])
      allow(generator).to receive(:site_elements_for_rule).and_return([])

      expected_hash = {
        match: nil,
        conditions: [].to_json,
        site_elements: [].to_json
      }

      expect(generator.rules).to eq([expected_hash])
    end

    it 'returns the proper hash when a single bar_id is passed as an option' do
      bar = SiteElement.create! element_subtype: 'email', rule: rule, contact_list: contact_list
      options = { bar_id: bar.id }

      generator = ScriptGenerator.new(site, options)
      allow(generator).to receive(:site_element_settings).and_return(id: bar.id, template_name: bar.element_subtype)

      allow(site).to receive(:rules).and_return([rule])

      expected_hash = {
        match: nil,
        conditions: [].to_json,
        site_elements: [{ id: bar.id, template_name: bar.element_subtype }].to_json
      }

      expect(generator.rules).to eq([expected_hash])
    end

    it 'renders all bar json when the render_paused_site_elements is true' do
      bar = SiteElement.create! element_subtype: 'email', rule: rule, paused: true, contact_list: contact_list
      options = { render_paused_site_elements: true }
      generator = ScriptGenerator.new(site, options)
      allow(generator).to receive(:site_element_settings).and_return(id: bar.id, template_name: bar.element_subtype, settings: { buffer_url: 'url' })

      allow(site).to receive(:rules).and_return([rule])

      expected_hash = {
        match: nil,
        conditions: [].to_json,
        site_elements: [{ id: bar.id, template_name: bar.element_subtype, settings: { buffer_url: 'url' } }].to_json
      }

      expect(generator.rules).to eq([expected_hash])
    end

    it 'renders only active bar json by default' do
      SiteElement.create! element_subtype: 'email', rule: rule, paused: true, contact_list: contact_list
      active_bar = SiteElement.create! element_subtype: 'traffic', rule: rule, paused: false
      generator = ScriptGenerator.new(site)
      allow(generator).to receive(:site_element_settings).and_return(id: active_bar.id, template_name: active_bar.element_subtype)

      allow(site).to receive(:rules).and_return([rule])

      expected_hash = {
        match: nil,
        conditions: [].to_json,
        site_elements: [{ id: active_bar.id, template_name: active_bar.element_subtype }].to_json
      }

      expect(generator.rules).to eq([expected_hash])
    end

    describe '#pro_secret' do
      it 'returns a random string (not hellobar)' do
        generator = ScriptGenerator.new(create(:site))
        expect(generator.pro_secret).to_not eq('hellobar')
      end
    end

    describe '#generate_script' do
      it 'does not compress the template if the compress option is not set' do
        generator = ScriptGenerator.new('site')
        allow(generator).to receive(:render).and_return('template')

        expect(Uglifier).not_to receive(:new)
        expect(generator).to receive(:render)

        generator.generate_script
      end

      it 'compresses the template when the compress option is true' do
        generator = ScriptGenerator.new('site', compress: true)
        allow(generator).to receive(:render).and_return('template')

        expect(ScriptGenerator.uglifier).to receive(:compress).with('template')

        generator.generate_script
      end
    end
  end

  describe '#condition_settings' do
    let(:condition) { create(:condition) }
    let(:generator) { ScriptGenerator.new(condition.rule.site) }

    it 'turns a condition into a hash' do
      expect(generator.send(:condition_settings, condition))
        .to eq(segment: condition.segment_key, operand: condition.operand, value: condition.value)
    end

    it 'uses the custom segment for CustomConditions' do
      condition.segment = 'CustomCondition'
      condition.custom_segment = 'ABC'
      expect(generator.send(:condition_settings, condition))
        .to eq(segment: 'ABC', operand: condition.operand, value: condition.value)
    end

    it 'adds the timezone offset when present for TimeConditions' do
      allow(condition).to receive(:timezone_offset) { '9999' }

      condition.segment = 'CustomCondition'
      condition.custom_segment = 'ABC'
      expect(generator.send(:condition_settings, condition))
        .to eq(
          segment: 'ABC',
          operand: condition.operand,
          value: condition.value,
          timezone_offset: condition.timezone_offset
        )
    end
  end
end
