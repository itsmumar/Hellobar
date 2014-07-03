require 'spec_helper'

describe ScriptGenerator, '#render' do
  let(:site) { double 'site', id: '1337', rules: [], site_elements: double('site_elements', active: []) }
  let(:generator) { ScriptGenerator.new(site) }

  it 'renders the site it variable' do
    expected_string = "var HB_SITE_ID = #{site.id};"

    generator.render.should include(expected_string)
  end

  it 'renders the backend host variable' do
    Hellobar::Settings.stub(:[]).with(:tracking_host).and_return("hi-there.hellobar.com")
    expected_string = "HB_BACKEND_HOST = \"hi-there.hellobar.com\";"

    generator.render.should include(expected_string)
  end

  it 'renders the hellobar base file' do
    hellobar_base = File.read("#{Rails.root}/vendor/assets/javascripts/hellobar.base.js")

    generator.render.should include(hellobar_base)
  end

  it 'includes the minified hellobar css' do
    generator.stub :hellobar_container_css
    hellobar_css = File.read("#{Rails.root}/vendor/assets/stylesheets/hellobar_script.css")

    CSSMin.should_receive(:minify).with(hellobar_css).and_return(hellobar_css)

    generator.render.should include(hellobar_css.to_json)
  end

  it 'includes the hellobar container css' do
    generator.stub :hellobar_base_css
    container_css = File.read("#{Rails.root}/vendor/assets/stylesheets/hellobar_script_container.css")

    CSSMin.should_receive(:minify).with(container_css).and_return(container_css)

    generator.render.should include(container_css.to_json)
  end

  it 'renders the initialization of the hellobar queue object' do
    hbq_initialization = "_hbq = new HBQ();"

    generator.render.should include(hbq_initialization)
  end

  context 'when templates are present' do
    it 'renders the setTemplate function on HB with the template name and markup' do
      template = { name: 'yey name', markup: 'yey markup' }
      generator.stub templates: [template]

      expected_string = "HB.setTemplate(\"yey name\", yey markup);"

      generator.render.should include(expected_string)
    end

    it 'renders only the setTemplate definition and 1 call per bar type' do
      bar = double 'bar', bar_type: 'traffic'
      site.stub site_elements: double('site_elements', active: [bar, bar])

      generator = ScriptGenerator.new site

      generator.render.scan('setTemplate').size.should == 2
    end

    it 'renders the setTemplate definition and 1 call per bar type for multiple types' do
      traffic_bar = double 'bar', bar_type: 'traffic'
      email_bar = double 'bar', bar_type: 'email'
      site.stub site_elements: double('site_elements', active: [traffic_bar, email_bar])

      generator = ScriptGenerator.new site

      generator.render.scan('setTemplate').size.should == 3
    end
  end

  context 'when rules are present' do
    it 'does not return any eligibility rules when eligibility is disabled' do
      generator = ScriptGenerator.new(site, { :disable_eligibility => true })
      rule = Rule.new
      date_condition = DateCondition.new value: { 'start_date' => 1_000, 'end_date' => 2_000 }, operand: Condition::OPERANDS[:is_after]
      url_condition = UrlCondition.new value: 'http://good.com', operand: Condition::OPERANDS[:is]
      rule.stub conditions: [date_condition, url_condition]
      site.stub rules: [rule]

      unexpected_pattern = /\(new Date\(\)\)\.getTime\(\)\/(.*)|HB.umatch(.*);/

      generator.render.should_not match(unexpected_pattern)
    end

    it 'has a start date constraint when present' do
      rule = Rule.new
      condition = DateCondition.new value: { 'start_date' => 1_000 }, operand: Condition::OPERANDS[:is_after]
      rule.stub conditions: [condition]
      site.stub rules: [rule]

      expected_string = '(new Date()).getTime()/1000 > 1000)'

      generator.render.should include(expected_string)
    end

    it 'does NOT have a start date constraint when not present' do
      rule = Rule.new
      site.stub rules: [rule]

      unexpected_string = /\(new Date\(\)\)\.getTime\(\)\/1000/

      generator.render.should_not match(unexpected_string)
    end

    it 'has an end date constraint when present' do
      rule = Rule.new
      condition = DateCondition.new value: { 'end_date' => 20_000 }, operand: Condition::OPERANDS[:is_before]
      rule.stub conditions: [condition]
      site.stub rules: [rule]

      expected_string = '(new Date()).getTime()/1000 < 20000)'

      generator.render.should include(expected_string)
    end

    it 'does NOT have a start date constraint when not present' do
      rule = Rule.new
      site.stub rules: [rule]

      unexpected_string = /\(new Date\(\)\)\.getTime\(\)\//

      generator.render.should_not match(unexpected_string)
    end

    it 'adds an exlusion constraint for all blacklisted URLs' do
      rule = Rule.new
      conditions = [UrlCondition.new(value: '/signup', operand: Condition::OPERANDS[:excludes] )]
      rule.stub site_elements: double('site_elements', active: []), attributes: {}, conditions: conditions
      site.stub rules: [rule]

      expected_string = "(!HB.umatch(\"/signup\", document.location))"

      generator.render.should include(expected_string)
    end

    it 'converts excluded urls to paths' do
      rule = Rule.new
      conditions = [UrlCondition.new(value: 'http://soamazing.com/signup', operand: Condition::OPERANDS[:excludes])]
      rule.stub site_elements: double('site_elements', active: []), attributes: {}, conditions: conditions
      site.stub rules: [rule]

      expected_string = "(!HB.umatch(\"/signup\", document.location))"

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

      expected_string = "(HB.umatch(\"/signup\", document.location));"

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
  let(:site) { double 'site', id: '1337', rules: [], site_elements: [] }
  let(:generator) { ScriptGenerator.new(site) }

  it 'returns the proper array of hashes for a sites rules' do
    rule = Rule.new id: 1
    site.stub rules: [rule]
    generator.stub site_elements_for_rule: []

    expected_hash = {
      bar_json: [].to_json,
      priority: 1,
      metadata: { "id" => 1 }.to_json,
      rule_eligibility: 'return true;}'
    }

    generator.rules.should == [expected_hash]
  end

  it 'returns the proper hash when a single bar_id is passed as an option' do
    rule = Rule.create
    bar = SiteElement.create bar_type: 'email', rule: rule
    options = { bar_id: bar.id }

    generator = ScriptGenerator.new(site, options)
    generator.stub site_element_settings: {id: bar.id, template_name: bar.bar_type}

    site.stub rules: [rule]

    expected_hash = {
      bar_json: [{ id: bar.id, template_name: bar.bar_type }].to_json,
      priority: 1,
      metadata: { "id" => rule.id }.to_json,
      rule_eligibility: 'return true;}'
    }

    generator.rules.should == [expected_hash]
  end

  it 'renders all bar json when the render_paused_site_elements is true' do
    rule = Rule.create
    bar = SiteElement.create bar_type: 'email', rule: rule, paused: true
    options = { render_paused_site_elements: true }
    generator = ScriptGenerator.new(site, options)
    generator.stub site_element_settings: { id: bar.id, template_name: bar.bar_type, settings: { buffer_url: 'url' }}

    site.stub rules: [rule]

    expected_hash = {
      bar_json: [{ id: bar.id, template_name: bar.bar_type, settings: { buffer_url: 'url' }}].to_json,
      priority: 1,
      metadata: { "id" => rule.id }.to_json,
      rule_eligibility: 'return true;}'
    }

    generator.rules.should == [expected_hash]
  end

  it 'renders only active bar json by default' do
    rule = Rule.create
    paused = SiteElement.create! bar_type: 'email', rule: rule, paused: true
    active_bar = SiteElement.create! bar_type: 'traffic', rule: rule, paused: false
    generator = ScriptGenerator.new(site)
    generator.stub site_element_settings: { id: active_bar.id, template_name: active_bar.bar_type }

    site.stub rules: [rule]

    expected_hash = {
      bar_json: [{ id: active_bar.id, template_name: active_bar.bar_type }].to_json,
      priority: 1,
      metadata: { "id" => rule.id }.to_json,
      rule_eligibility: 'return true;}'
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
