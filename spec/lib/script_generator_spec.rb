require 'spec_helper'

describe ScriptGenerator do
  fixtures :all
  extend ThemeMacros

  before do
    Hello::DataAPI.stub(:lifetime_totals => nil)
  end

  describe "#render" do
    let(:site) { sites(:zombo) }
    let(:generator) { ScriptGenerator.new(site) }

    it 'renders the site id variable' do
      expected_string = "HB_SITE_ID = #{site.id};"

      generator.render.should include(expected_string)
    end

    it 'renders the backend host variable' do
      original_setting = Hellobar::Settings[:tracking_host]
      Hellobar::Settings[:tracking_host] = "hi-there.hellobar.com"
      expected_string = "HB_BACKEND_HOST = \"hi-there.hellobar.com\";"

      generator.render.should include(expected_string)
      Hellobar::Settings[:tracking_host] = original_setting
    end

    it 'renders the HB_TZ timezone variable' do
      site.stub timezone: 'America/Chicago'
      Time.zone = 'America/Chicago'
      expected_string = "HB_TZ = \"#{Time.zone.now.formatted_offset}\";"

      generator.render.should include(expected_string)
    end

    it 'includes the minified hellobar css' do
      generator.stub :hellobar_container_css
      hellobar_css = File.read("#{Rails.root}/vendor/assets/stylesheets/site_elements/common.css")
      element_css = File.read("#{Rails.root}/vendor/assets/stylesheets/site_elements/bar/element.css")

      CSSMin.stub(:minify) { |x| x }
      result = generator.render

      result.should include(hellobar_css.to_json[1..-2])
      result.should include(element_css.to_json[1..-2])
    end

    it 'includes the hellobar container css' do
      generator.stub :hellobar_element_css
      allow(generator).to receive(:pro_secret) { 'random' }
      container_css = File.read("#{Rails.root}/vendor/assets/stylesheets/site_elements/container_common.css")
      container_css.gsub!('hellobar-container', 'random-container')
      element_container_css = File.read("#{Rails.root}/vendor/assets/stylesheets/site_elements/bar/container.css")
      element_container_css.gsub!('hellobar-container', 'random-container')

      CSSMin.stub(:minify) { |x| x }
      result = generator.render

      result.should include(container_css.to_json[1..-2])
      result.should include(element_container_css.to_json[1..-2])
    end

    it 'renders the initialization of the hellobar queue object' do
      hbq_initialization = "_hbq = new HBQ();"

      generator.render.should include(hbq_initialization)
    end

    context 'when templates are present' do
      it 'renders the setTemplate function on HB with the template name and markup' do
        template = { name: 'yey name', markup: 'yey markup' }
        generator.stub templates: [template]
        generator.stub(:hellobar_container_css)
        generator.stub(:hellobar_element_css)

        expected_string = "HB.setTemplate(\"yey name\", yey markup);"

        generator.render.should include(expected_string)
      end

      it 'renders only the setTemplate definition and 1 call per bar type' do
        bar = Bar.new(element_subtype: 'traffic', theme_id: 'classic')
        site.stub(site_elements: double('site_elements', active: [bar, bar], active_content_upgrades: [], none?: true ))

        generator = ScriptGenerator.new site

        generator.render.scan('setTemplate').size.should == 2
      end

      it 'renders the setTemplate definition and 1 call per bar type for multiple types' do
        traffic_bar = Bar.new(element_subtype: 'traffic', theme_id: 'classic')
        email_bar = Bar.new(element_subtype: 'email', theme_id: 'classic')
        site.stub site_elements: double('site_elements', active: [traffic_bar, email_bar], active_content_upgrades: [], none?: true)

        generator = ScriptGenerator.new site

        generator.render.scan('setTemplate').size.should == 3
      end
    end

    context 'when rules are present' do
      it 'has a start date constraint when present' do
        rule = Rule.new
        condition = Condition.new value: { 'start_date' => Date.new(2000, 01, 01) }, operand: Condition::OPERANDS[:after], segment: "DateCondition"
        rule.stub conditions: [condition]
        site.stub rules: [rule]

        expected_string = 'HB.addRule("", [{"segment":"dt","operand":"is after","value":{"start_date":"2000-01-01"}}], [])'

        generator.render.should include(expected_string)
      end

      it 'does NOT have a start date constraint when not present' do
        rule = Rule.new
        site.stub rules: [rule]

        expected_string = 'HB.addRule("", [], [])}'

        generator.render.should include(expected_string)
      end

      it 'has an end date constraint when present' do
        rule = Rule.new
        condition = Condition.new value: { 'end_date' => Date.new(2015, 01, 01) }, operand: Condition::OPERANDS[:before], segment: "DateCondition"
        rule.stub conditions: [condition]
        site.stub rules: [rule]

        expected_string = 'HB.addRule("", [{"segment":"dt","operand":"is before","value":{"end_date":"2015-01-01"}}], [])}'

        generator.render.should include(expected_string)
      end

      it 'does NOT have a start date constraint when not present' do
        rule = Rule.new
        site.stub rules: [rule]

        expected_string = 'HB.addRule("", [], [])}'

        generator.render.should include(expected_string)
      end

      it 'adds an exlusion constraint for all blacklisted URLs' do
        rule = Rule.new
        conditions = [Condition.new(value: '/signup', operand: :does_not_include, segment: "UrlCondition" )]
        rule.stub site_elements: double('site_elements', active: []), attributes: {}, conditions: conditions
        site.stub rules: [rule]

        expected_string = 'HB.addRule("", [{"segment":"pu","operand":"does_not_include","value":"/signup"}], [])'

        generator.render.should include(expected_string)
      end

      it 'converts does_not_include urls to paths' do
        rule = Rule.new
        conditions = [Condition.new(value: 'http://soamazing.com/signup', operand: :does_not_include, segment: "UrlCondition" )]
        rule.stub site_elements: double('site_elements', active: []), attributes: {}, conditions: conditions
        site.stub rules: [rule]

        expected_string = 'HB.addRule("", [{"segment":"pu","operand":"does_not_include","value":"http://soamazing.com/signup"}], [])}'

        generator.render.should include(expected_string)
      end

      it 'does NOT have exclusion constraints when no sites are blacklisted' do
        rule = Rule.new
        site.stub rules: [rule]

        expected_string = Regexp.new /HB.umatch(.*)/

        generator.render.should_not match(expected_string)
      end

      it 'adds an inclusion constraint for all whitelisted URLs' do
        rule = Rule.new
        conditions = [Condition.new(value: '/signup', operand: Condition::OPERANDS[:includes], segment: "UrlCondition" )]
        rule.stub conditions: conditions
        site.stub rules: [rule]

        expected_string = 'HB.addRule("", [{"segment":"pu","operand":"includes","value":"/signup"}], [])'

        generator.render.should include(expected_string)
      end

      it 'does NOT have inclusion constraints when no sites are whitelisted' do
        rule = Rule.new
        generator.stub rules: [rule]

        expected_string = Regexp.new /HB.umatch(.*)/

        generator.render.should_not match(expected_string)
      end
    end

    context "site element has a theme" do
      use_theme_fixtures
      before do
        create(:site_element, rule: site.rules.last, theme_id: 'beige-test')
      end

      it 'includes the container theme css' do
        expected_string = "#beige-container{border:1px}"

        expect(generator.render).to include(expected_string)
      end

      it 'includes the element theme css' do
        expected_string = "#beige-element{border:1px}"

        expect(generator.render).to include(expected_string)
      end
    end

    context "site element does not have a theme" do
      use_theme_fixtures

      it 'does not includes the container theme css' do
        expected_string = "#beige-container{border:1px}"

        expect(generator.render).to_not include(expected_string)
      end

      it 'does not include the element theme css' do
        expected_string = "#beige-element{border:1px}"
        expect(generator.render).to_not include(expected_string)
      end
    end
  end

  describe '#rules' do
    let(:site) { sites(:zombo) }
    let(:contact_list) { contact_lists(:zombo_contacts) }
    let(:generator) { ScriptGenerator.new(site) }

    it 'returns the proper array of hashes for a sites rules' do
      rule = Rule.new id: 1
      site.stub rules: [rule]
      generator.stub site_elements_for_rule: []

      expected_hash = {
        match: nil,
        conditions: [].to_json,
        site_elements: [].to_json
      }

      generator.rules.should == [expected_hash]
    end

    it 'returns the proper hash when a single bar_id is passed as an option' do
      rule = rules(:horsebike)
      bar = SiteElement.create! element_subtype: 'email', rule: rule, contact_list: contact_list
      options = { bar_id: bar.id }

      generator = ScriptGenerator.new(site, options)
      generator.stub site_element_settings: {id: bar.id, template_name: bar.element_subtype}

      site.stub rules: [rule]

      expected_hash = {
        match: nil,
        conditions: [].to_json,
        site_elements: [{ id: bar.id, template_name: bar.element_subtype }].to_json
      }

      generator.rules.should == [expected_hash]
    end

    it 'renders all bar json when the render_paused_site_elements is true' do
      rule = rules(:horsebike)
      bar = SiteElement.create! element_subtype: 'email', rule: rule, paused: true, contact_list: contact_list
      options = { render_paused_site_elements: true }
      generator = ScriptGenerator.new(site, options)
      generator.stub site_element_settings: { id: bar.id, template_name: bar.element_subtype, settings: { buffer_url: 'url' }}

      site.stub rules: [rule]

      expected_hash = {
        match: nil,
        conditions: [].to_json,
        site_elements: [{ id: bar.id, template_name: bar.element_subtype, settings: { buffer_url: 'url' }}].to_json
      }

      generator.rules.should == [expected_hash]
    end

    it 'renders only active bar json by default' do
      rule = rules(:horsebike)
      paused = SiteElement.create! element_subtype: 'email', rule: rule, paused: true, contact_list: contact_list
      active_bar = SiteElement.create! element_subtype: 'traffic', rule: rule, paused: false
      generator = ScriptGenerator.new(site)
      generator.stub site_element_settings: { id: active_bar.id, template_name: active_bar.element_subtype }

      site.stub rules: [rule]

      expected_hash = {
        match: nil,
        conditions: [].to_json,
        site_elements: [{ id: active_bar.id, template_name: active_bar.element_subtype }].to_json
      }

      generator.rules.should == [expected_hash]
    end

    describe '#pro_secret' do
      it 'returns a random string (not hellobar)' do
        generator = ScriptGenerator.new(create(:site))
        expect(generator.pro_secret).to_not eq("hellobar")
      end
    end

    describe '#generate_script' do
      it 'does not compress the template if the compress option is not set' do
        generator = ScriptGenerator.new('site')
        generator.stub :render => 'template'

        Uglifier.should_not_receive(:new)
        generator.should_receive(:render)

        generator.generate_script
      end

      it 'compresses the template when the compress option is true' do
        generator = ScriptGenerator.new('site', { compress: true })
        generator.stub :render => 'template'

        uglifier = Uglifier.new
        Uglifier.should_receive(:new).and_return(uglifier)
        uglifier.should_receive(:compress).with('template')

        generator.generate_script
      end
    end
  end

  describe "#condition_settings" do
    let(:condition) { create(:condition) }
    let(:generator) { ScriptGenerator.new(condition.rule.site) }

    it "turns a condition into a hash" do
      expect(generator.send(:condition_settings, condition)).to eq({
        segment: condition.segment_key,
        operand: condition.operand,
        value: condition.value
      })
    end

    it "uses the custom segment for CustomConditions" do
      condition.segment = 'CustomCondition'
      condition.custom_segment = 'ABC'
      expect(generator.send(:condition_settings, condition)).to eq({
        segment: 'ABC',
        operand: condition.operand,
        value: condition.value
      })
    end

    it "adds the timezone offset when present for TimeConditions" do
      allow(condition).to receive(:timezone_offset) { "9999" }

      condition.segment = 'CustomCondition'
      condition.custom_segment = 'ABC'
      expect(generator.send(:condition_settings, condition)).to eq({
        segment: 'ABC',
        operand: condition.operand,
        value: condition.value,
        timezone_offset: condition.timezone_offset
      })
    end
  end
end
