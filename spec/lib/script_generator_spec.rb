require 'spec_helper'

describe ScriptGenerator, '#render' do
  let(:site) { double 'site', id: '1337', rules: [], bars: [] }
  let(:config) { double 'config', hb_backend_host: 'backend_host' }
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
      double_template = { name: 'yey name', markup: 'yey markup' }
      generator.stub templates: [double_template]

      expected_string = 'HB.setTemplate("yey name", "yey markup");'

      generator.render.should include(expected_string)
    end
  end

  context 'when rules are present' do
    it 'does not return any eligibility rules when eligibility is disabled' do
      generator = ScriptGenerator.new site, config, { :disable_eligibility => true }
      rule = Rule.new
      rule_setting = RuleSetting.new start_date: 1_000, end_date: 2_000, include_urls: ['url'], exclude_urls: ['other url']
      rule.stub rule_setting: rule_setting
      site.stub rules: [rule]

      unexpected_pattern = /if \( \(new Date\(\)\)\.getTime\(\)\/(.*) return (.*);|HB.umatch(.*) return (.*);/

      generator.render.should_not match(unexpected_pattern)
    end

    it 'has a start date constraint when present' do
      rule = double 'rule', start_date: 1_000
      generator.stub rules: [rule]

      expected_string = 'if ( (new Date()).getTime()/1000 < 1000) return false;'

      generator.render.should include(expected_string)
    end

    it 'does NOT have a start date constraint when not present' do
      rule = double 'rule', start_date: nil
      generator.stub rules: [rule]

      unexpected_string = /if \( \(new Date\(\)\)\.getTime\(\)\/1000 <(.*) return false;/

      generator.render.should_not match(unexpected_string)
    end

    it 'has an end date constraint when present' do
      rule = double 'rule', end_date: 2_000
      generator.stub rules: [rule]

      expected_string = 'if ( (new Date()).getTime()/1000 > 2000) return false;'

      generator.render.should include(expected_string)
    end

    it 'does NOT have a start date constraint when not present' do
      rule = double 'rule', end_date: nil
      generator.stub rules: [rule]

      unexpected_string = /if \( \(new Date\(\)\)\.getTime\(\)\/1000 >(.*)return false;/

      generator.render.should_not match(unexpected_string)
    end

    it 'adds an exlusion constraint for all blacklisted URLs' do
      rule = double 'rule', exclude_urls: [{ url: 'http://amazing.com' }]
      generator.stub rules: [rule]

      expected_string = "if (HB.umatch(\"http://amazing.com\", document.location)) return false;"

      generator.render.should include(expected_string)
    end

    it 'does NOT have exclusion constraints when no sites are blacklisted' do
      rule = double 'rule', exclude_urls: []
      generator.stub rules: [rule]

      expected_string = Regexp.new /HB.umatch(.*) return false;/

      generator.render.should_not match(expected_string)
    end

    it 'adds an inclusion constraint for all whitelisted URLs' do
      rule = double 'rule', include_urls: [{ url: 'http://soamazing.com' }]
      generator.stub rules: [rule]

      expected_string = "if (HB.umatch(\"http://soamazing.com\", document.location)) return true;"

      generator.render.should include(expected_string)
    end

    it 'does NOT have inclusion constraints when no sites are whitelisted' do
      rule = double 'rule', include_urls: []
      generator.stub rules: [rule]

      expected_string = Regexp.new /HB.umatch(.*) return true;/

      generator.render.should_not match(expected_string)
    end
  end

  xit 'completely replicates the old script generation method' do
    js_fixture = File.read("#{Rails.root}/spec/fixtures/generated_site_script.js")

    # need to add a ton of bar settings!
    # lets gsub and only test if remains_at_top is there

    # remains_at_top: true
    # open_in_new_window: false
    # pushes_page_down: true
    # closable: false
    # show_wait: 0
    # hide_after: 0
    # wiggle_wait: 0
    # link_style: 'button'
    # message: 'Get Rock Pillow giveaways and exclusive coupons'
    # link_text: 'Yes! Send Me a Coupon'
    # bar_color: '18adfe'
    # text_color: 'ffffff'
    # link_color: 'ffffff'
    # border_color: 'ffffff'
    # texture: 'none'
    # show_border: false
    # font: 'Helvetica,Arial,sans-serif'
    # tab_side: 'right'
    # button_color: "000000"
    # size: "regular"
    # thank_you_text: "Thank you for signing up!"
    # id: 17460,
    # target: null
    # template_name": "CollectEmail"

    site = Site.new
    rule = Rule.new site: site
    setting = RuleSetting.new rule: rule
    bar = Bar.new goal: 'CollectEmail', rule: rule
    bar.stub :rule_setting => setting
    rule.stub bars: [bar]
    site.stub id: 14797, bars: [bar], rules: [rule]

    generator = ScriptGenerator.new(site, config)
    generated = generator.render.gsub(/\s/, '')
    fixture = js_fixture.gsub(/\s/, '')

    generated.should == fixture
  end
end
