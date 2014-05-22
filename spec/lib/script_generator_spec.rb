require 'spec_helper'

describe ScriptGenerator, '#render' do
  let(:site) { mock 'site', id: '1337', rules: [] }
  let(:config) { mock 'config', hb_backend_host: 'backend_host' }
  let(:generator) { ScriptGenerator.new(site, config) }

  it 'renders the site it variable' do
    expected_string = "var HB_SITE_ID = \"#{site.id}\";"

    generator.render.should include(expected_string)
  end

  it 'renders the backend host variable' do
    expected_string = "HB_BACKEND_HOST = \"#{config.hb_backend_host}\";"

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
      mock_template = { name: 'yey name', markup: 'yey markup' }
      generator.stub templates: [mock_template]

      expected_string = 'HB.setTemplate("yey name", "yey markup");'

      generator.render.should include(expected_string)
    end
  end

  context 'when rules are present' do
    it 'simply returns true when eligibility is disabled'
    it 'has a start date constraint when present' do
      rule = mock 'rule', start_date: 1_000
      generator.stub rules: [rule]

      expected_string = 'if ( (new Date()).getTime()/1000 < 1000) return false;'

      generator.render.should include(expected_string)
    end

    it 'does NOT have a start date constraint when not present' do
      rule = mock 'rule', start_date: nil
      generator.stub rules: [rule]

      unexpected_string = /if \( \(new Date\(\)\)\.getTime\(\)\/1000 <(.*) return false;/

      generator.render.should_not match(unexpected_string)
    end

    it 'has an end date constraint when present' do
      rule = mock 'rule', end_date: 2_000
      generator.stub rules: [rule]

      expected_string = 'if ( (new Date()).getTime()/1000 > 2000) return false;'

      generator.render.should include(expected_string)
    end

    it 'does NOT have a start date constraint when not present' do
      rule = mock 'rule', end_date: nil
      generator.stub rules: [rule]

      unexpected_string = /if \( \(new Date\(\)\)\.getTime\(\)\/1000 >(.*)return false;/

      generator.render.should_not match(unexpected_string)
    end

    it 'adds an exlusion constraint for all blacklisted URLs' do
      rule = mock 'rule', exclude_urls: [{ url: 'http://amazing.com' }]
      generator.stub rules: [rule]

      expected_string = "if (HB.umatch(\"http://amazing.com\", document.location)) return false;"

      generator.render.should include(expected_string)
    end

    it 'does NOT have exclusion constraints when no sites are blacklisted' do
      rule = mock 'rule', exclude_urls: []
      generator.stub rules: [rule]

      expected_string = Regexp.new /HB.umatch(.*) return false;/

      generator.render.should_not match(expected_string)
    end

    it 'adds an inclusion constraint for all whitelisted URLs' do
      rule = mock 'rule', include_urls: [{ url: 'http://soamazing.com' }]
      generator.stub rules: [rule]

      expected_string = "if (HB.umatch(\"http://soamazing.com\", document.location)) return true;"

      generator.render.should include(expected_string)
    end

    it 'does NOT have inclusion constraints when no sites are whitelisted' do
      rule = mock 'rule', include_urls: []
      generator.stub rules: [rule]

      expected_string = Regexp.new /HB.umatch(.*) return true;/

      generator.render.should_not match(expected_string)
    end
  end

  xit 'completely replicates the old script generation method' do
    # need to setup the objects to replicate rockpillows.com site graph
    js_fixture = File.read("#{Rails.root}/spec/fixtures/generated_site_script.js")

    generator.render.should == js_fixture
  end
end

describe ScriptGenerator, '#rule_start_date' do
  let(:generator) { ScriptGenerator.new('site', 'config') }
  let(:rule_setting) { RuleSetting.new }

  it 'returns the start date as an integer if present' do
    rule_setting.start_date = Time.parse('1985-11-05 01:20:00')

    generator.rule_start_date(rule_setting).should == rule_setting.start_date.to_i
  end

  it 'returns nil if the start date is not present' do
    generator.rule_start_date(rule_setting).should be_nil
  end
end

describe ScriptGenerator, '#rule_end_date' do
  let(:generator) { ScriptGenerator.new('site', 'config') }
  let(:rule_setting) { RuleSetting.new }

  it 'returns the end date as an integer if present' do
    rule_setting.end_date = Time.parse('1985-10-26 01:20:00')

    generator.rule_end_date(rule_setting).should == rule_setting.end_date.to_i
  end

  it 'returns nil if the end date is not present' do
    generator.rule_end_date(rule_setting).should be_nil
  end
end
