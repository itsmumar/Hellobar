require 'spec_helper'

describe ScriptGenerator, '#render' do
  let(:site) { double 'site', id: '1337', rule_sets: [], bars: double('bars', active: []) }
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
  end

  context 'when rule_sets are present' do
    it 'does not return any eligibility rule_sets when eligibility is disabled' do
      generator = ScriptGenerator.new(site, { :disable_eligibility => true })
      rule_set = RuleSet.new
      date_condition = DateCondition.new value: { 'start_date' => 1_000, 'end_date' => 2_000 }
      url_condition = UrlCondition.new value: { 'include_urls' => ['http://good.com'], 'exclude_urls' => ['http://other.com'] }
      rule_set.stub conditions: [date_condition, url_condition]
      site.stub rule_sets: [rule_set]

      unexpected_pattern = /if \( \(new Date\(\)\)\.getTime\(\)\/(.*) return (.*);|HB.umatch(.*) return (.*);/

      generator.render.should_not match(unexpected_pattern)
    end

    it 'has a start date constraint when present' do
      rule_set = double 'rule_set', start_date: 1_000
      generator.stub rule_sets: [rule_set]

      expected_string = 'if ( (new Date()).getTime()/1000 < 1000) return false;'

      generator.render.should include(expected_string)
    end

    it 'does NOT have a start date constraint when not present' do
      rule_set = double 'rule_set', start_date: nil
      generator.stub rule_sets: [rule_set]

      unexpected_string = /if \( \(new Date\(\)\)\.getTime\(\)\/1000 <(.*) return false;/

      generator.render.should_not match(unexpected_string)
    end

    it 'has an end date constraint when present' do
      rule_set = double 'rule_set', end_date: 2_000
      generator.stub rule_sets: [rule_set]

      expected_string = 'if ( (new Date()).getTime()/1000 > 2000) return false;'

      generator.render.should include(expected_string)
    end

    it 'does NOT have a start date constraint when not present' do
      rule_set = double 'rule_set', end_date: nil
      generator.stub rule_sets: [rule_set]

      unexpected_string = /if \( \(new Date\(\)\)\.getTime\(\)\/1000 >(.*)return false;/

      generator.render.should_not match(unexpected_string)
    end

    it 'adds an exlusion constraint for all blacklisted URLs' do
      rule_set = double 'rule_set', exclude_urls: [{ url: 'http://amazing.com' }]
      generator.stub rule_sets: [rule_set]

      expected_string = "if (HB.umatch(\"http://amazing.com\", document.location)) return false;"

      generator.render.should include(expected_string)
    end

    it 'does NOT have exclusion constraints when no sites are blacklisted' do
      rule_set = double 'rule_set', exclude_urls: []
      generator.stub rule_sets: [rule_set]

      expected_string = Regexp.new /HB.umatch(.*) return false;/

      generator.render.should_not match(expected_string)
    end

    it 'adds an inclusion constraint for all whitelisted URLs' do
      rule_set = double 'rule_set', include_urls: [{ url: 'http://soamazing.com' }]
      generator.stub rule_sets: [rule_set]

      expected_string = "if (HB.umatch(\"http://soamazing.com\", document.location)) return true;"

      generator.render.should include(expected_string)
    end

    it 'does NOT have inclusion constraints when no sites are whitelisted' do
      rule_set = double 'rule_set', include_urls: []
      generator.stub rule_sets: [rule_set]

      expected_string = Regexp.new /HB.umatch(.*) return true;/

      generator.render.should_not match(expected_string)
    end
  end
end

describe ScriptGenerator, '#rule_sets' do
  let(:site) { double 'site', id: '1337', rule_sets: [], bars: [] }
  let(:generator) { ScriptGenerator.new(site) }

  it 'returns the proper array of hashes for a sites rule_sets' do
    rule_set = RuleSet.new id: 1
    site.stub rule_sets: [rule_set]
    generator.stub bars_for_rule_set: []

    expected_hash = {
      bar_json: [].to_json,
      priority: 1,
      metadata: { "id" => 1 }.to_json,
      start_date: nil,
      end_date: nil,
      exclude_urls: nil,
      include_urls: nil
    }

    generator.rule_sets.should == [expected_hash]
  end

  it 'returns the proper hash when a single bar_id is passed as an option' do
    rule_set = RuleSet.create
    bar = Bar.create bar_type: 'email', rule_set: rule_set
    options = { bar_id: bar.id }

    generator = ScriptGenerator.new(site, options)
    generator.stub bar_settings: {id: bar.id, template_name: bar.bar_type}

    site.stub rule_sets: [rule_set]

    expected_hash = {
      bar_json: [{ id: bar.id, template_name: bar.bar_type }].to_json,
      priority: 1,
      metadata: { "id" => rule_set.id }.to_json,
      start_date: nil,
      end_date: nil,
      exclude_urls: nil,
      include_urls: nil
    }

    generator.rule_sets.should == [expected_hash]
  end

  it 'renders all bar json when the render_paused_bars is true' do
    rule_set = RuleSet.create
    bar = Bar.create bar_type: 'email', rule_set: rule_set, paused: true
    options = { render_paused_bars: true }
    generator = ScriptGenerator.new(site, options)
    generator.stub bar_settings: { id: bar.id, template_name: bar.bar_type, settings: { buffer_url: 'url' }}

    site.stub rule_sets: [rule_set]

    expected_hash = {
      bar_json: [{ id: bar.id, template_name: bar.bar_type, settings: { buffer_url: 'url' }}].to_json,
      priority: 1,
      metadata: { "id" => rule_set.id }.to_json,
      start_date: nil,
      end_date: nil,
      exclude_urls: nil,
      include_urls: nil
    }

    generator.rule_sets.should == [expected_hash]
  end

  it 'renders only active bar json by default' do
    rule_set = RuleSet.create
    paused = Bar.create! bar_type: 'email', rule_set: rule_set, paused: true
    active_bar = Bar.create! bar_type: 'traffic', rule_set: rule_set, paused: false
    generator = ScriptGenerator.new(site)
    generator.stub bar_settings: { id: active_bar.id, template_name: active_bar.bar_type }

    site.stub rule_sets: [rule_set]

    expected_hash = {
      bar_json: [{ id: active_bar.id, template_name: active_bar.bar_type }].to_json,
      priority: 1,
      metadata: { "id" => rule_set.id }.to_json,
      start_date: nil,
      end_date: nil,
      exclude_urls: nil,
      include_urls: nil
    }

    generator.rule_sets.should == [expected_hash]
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
