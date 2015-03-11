require 'spec_helper'

describe ScriptGenerator, '#render' do
  fixtures :all

  let(:site) { sites(:zombo) }
  let(:generator) { ScriptGenerator.new(site) }

  before do
    Hello::DataAPI.stub(:lifetime_totals => nil)
  end

  it 'renders the site id variable' do
    expected_string = "HB_SITE_ID = #{site.id};"

    generator.render.should include(expected_string)
  end

  it 'renders the backend host variable' do
    Hellobar::Settings.stub(:[]).with(:tracking_host).and_return("hi-there.hellobar.com")
    expected_string = "HB_BACKEND_HOST = \"hi-there.hellobar.com\";"

    generator.render.should include(expected_string)
  end

  it 'renders the HB_TZ timezone variable' do
    site.stub timezone: 'America/Chicago'
    expected_string = "HB_TZ = \"-06:00\";"

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
    container_css = File.read("#{Rails.root}/vendor/assets/stylesheets/site_elements/container_common.css")
    element_container_css = File.read("#{Rails.root}/vendor/assets/stylesheets/site_elements/bar/container.css")

    CSSMin.stub(:minify) { |x| x }
    result = generator.render

    result.should include(container_css.to_json[1..-2])
    result.should include(element_container_css.to_json[1..-2])
  end

  it 'renders the initialization of the hellobar queue object' do
    hbq_initialization = "_hbq = new HBQ();"

    generator.render.should include(hbq_initialization)
  end

  describe 'capabilities' do
    it 'sets branding variations to true if the site created at is > BRAND_VARIATION_DATE' do
      site.stub(:created_at).and_return(ScriptGenerator::BRAND_VARIATION_DATE + 1.day)
      generator.capabilities[:b_variation].should be_true
    end

    it 'sets branding variations to false if the site created at is < BRAND_VARIATION_DATE' do
      site.stub(:created_at).and_return(ScriptGenerator::BRAND_VARIATION_DATE - 1.day)
      generator.capabilities[:b_variation].should be_false
    end
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
      bar = Bar.new(element_subtype: 'traffic')
      site.stub(site_elements: double('site_elements', active: [bar, bar], none?: true ))

      generator = ScriptGenerator.new site

      generator.render.scan('setTemplate').size.should == 2
    end

    it 'renders the setTemplate definition and 1 call per bar type for multiple types' do
      traffic_bar = Bar.new(element_subtype: 'traffic')
      email_bar = Bar.new(element_subtype: 'email')
      site.stub site_elements: double('site_elements', active: [traffic_bar, email_bar], none?: true)

      generator = ScriptGenerator.new site

      generator.render.scan('setTemplate').size.should == 3
    end
  end

  context 'when rules are present' do
    it 'has a start date constraint when present' do
      rule = Rule.new
      condition = DateCondition.new value: { 'start_date' => Date.new(2000, 01, 01) }, operand: Condition::OPERANDS[:after]
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
      condition = DateCondition.new value: { 'end_date' => Date.new(2015, 01, 01) }, operand: Condition::OPERANDS[:before]
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
      conditions = [UrlCondition.new(value: '/signup', operand: :does_not_include )]
      rule.stub site_elements: double('site_elements', active: []), attributes: {}, conditions: conditions
      site.stub rules: [rule]

      expected_string = 'HB.addRule("", [{"segment":"pu","operand":"does_not_include","value":"/signup"}], [])'

      generator.render.should include(expected_string)
    end

    it 'converts does_not_include urls to paths' do
      rule = Rule.new
      conditions = [UrlCondition.new(value: 'http://soamazing.com/signup', operand: :does_not_include )]
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
      conditions = [UrlCondition.new(value: '/signup', operand: Condition::OPERANDS[:includes] )]
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
end

describe ScriptGenerator, '#rules' do
  fixtures :all

  let(:site) { sites(:zombo) }
  let(:contact_list) { contact_lists(:zombo) }
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
      site_elements: [{ id: active_bar.id, template_name: active_bar.element_subtype }].to_json,
    }

    generator.rules.should == [expected_hash]
  end
end

describe ScriptGenerator, '#generate_script' do
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
