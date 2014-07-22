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
      bar = double 'bar', element_subtype: 'traffic'
      site.stub site_elements: double('site_elements', active: [bar, bar])

      generator = ScriptGenerator.new site

      generator.render.scan('setTemplate').size.should == 2
    end

    it 'renders the setTemplate definition and 1 call per bar type for multiple types' do
      traffic_bar = double 'bar', element_subtype: 'traffic'
      email_bar = double 'bar', element_subtype: 'email'
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
      condition = DateCondition.new value: { 'start_date' => Date.new(2000, 01, 01) }, operand: Condition::OPERANDS[:is_after]
      rule.stub conditions: [condition]
      site.stub rules: [rule]

      expected_string = '(HB.comparableDate("auto") >= "2000/01/01")'

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
      condition = DateCondition.new value: { 'end_date' => Date.new(2015, 01, 01) }, operand: Condition::OPERANDS[:is_before]
      rule.stub conditions: [condition]
      site.stub rules: [rule]

      expected_string = '(HB.comparableDate("auto") <= "2015/01/01")'

      generator.render.should include(expected_string)
    end

    it 'does NOT have a start date constraint when not present' do
      rule = Rule.new
      site.stub rules: [rule]

      unexpected_string = /\(new Date\(\)\)\.getTime\(\)\//

      generator.render.should_not match(unexpected_string)
    end

    describe 'compare dates with timezones' do
      let(:rule) { Rule.new }
      before do
        Time.zone = "UTC"
        Timecop.freeze(Time.zone.local(2000))
        expect( Time.zone.now.to_s ).to eq "2000-01-01 00:00:00 UTC"
      end
      after { Timecop.return }

      it 'outputs correct javascript when timezone nil' do
        condition = DateCondition.new value: { 'start_date' => Date.new(2000, 01, 01), 'timezone' => nil }, operand: Condition::OPERANDS[:is_after]
        rule.stub conditions: [condition]
        site.stub rules: [rule]

        expected_string = '(HB.comparableDate("auto") >= "2000/01/01")'

        generator.render.should include(expected_string)
      end

      it 'correctly compares dates when timezone is prescribed in condition' do
        rule = Rule.new
        condition = DateCondition.new value: { 'start_date' => Date.new(2000, 01, 01), 'timezone' => 'America/Chicago' }, operand: Condition::OPERANDS[:is_after]
        rule.stub conditions: [condition]
        site.stub rules: [rule]

        # comparableDate() would return 2000/01/01 +06:00
        expected_string = '(HB.comparableDate() >= "2000/01/01 +06:00")'

        generator.render.should include(expected_string)
      end
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
  fixtures :all

  let(:site) { sites(:zombo) }
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
    rule = Rule.create! site: site
    bar = SiteElement.create! element_subtype: 'email', rule: rule
    options = { bar_id: bar.id }

    generator = ScriptGenerator.new(site, options)
    generator.stub site_element_settings: {id: bar.id, template_name: bar.element_subtype}

    site.stub rules: [rule]

    expected_hash = {
      bar_json: [{ id: bar.id, template_name: bar.element_subtype }].to_json,
      priority: 1,
      metadata: { "id" => rule.id }.to_json,
      rule_eligibility: 'return true;}'
    }

    generator.rules.should == [expected_hash]
  end

  it 'renders all bar json when the render_paused_site_elements is true' do
    rule = Rule.create! site: site
    bar = SiteElement.create! element_subtype: 'email', rule: rule, paused: true
    options = { render_paused_site_elements: true }
    generator = ScriptGenerator.new(site, options)
    generator.stub site_element_settings: { id: bar.id, template_name: bar.element_subtype, settings: { buffer_url: 'url' }}

    site.stub rules: [rule]

    expected_hash = {
      bar_json: [{ id: bar.id, template_name: bar.element_subtype, settings: { buffer_url: 'url' }}].to_json,
      priority: 1,
      metadata: { "id" => rule.id }.to_json,
      rule_eligibility: 'return true;}'
    }

    generator.rules.should == [expected_hash]
  end

  it 'renders only active bar json by default' do
    rule = Rule.create! site: site
    paused = SiteElement.create! element_subtype: 'email', rule: rule, paused: true
    active_bar = SiteElement.create! element_subtype: 'traffic', rule: rule, paused: false
    generator = ScriptGenerator.new(site)
    generator.stub site_element_settings: { id: active_bar.id, template_name: active_bar.element_subtype }

    site.stub rules: [rule]

    expected_hash = {
      bar_json: [{ id: active_bar.id, template_name: active_bar.element_subtype }].to_json,
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

describe ScriptGenerator, '#comparable_date' do
  fixtures :sites

  let(:site) { sites(:zombo) }
  let(:generator) { ScriptGenerator.new(site) }

  before do
    Time.zone = "UTC"
    # freeze time at the new millenium baby
    Timecop.freeze( Time.zone.local(2000) )

    # these tests all live in UTC
    expect(Time.current.to_s).to eq "2000-01-01 00:00:00 UTC"
  end

  after { Timecop.return }

  it 'should handle western hemisphere timezones' do
    expect( Time.zone.name ).to eq "UTC"
    # Ball just dropped in London
    cond = DateCondition.new(value: { 'start_date' => Date.new(2000, 1, 1), 'timezone' => 'UTC' }, operand: Condition::OPERANDS[:is_after])
    expect( cond.comparable_start_date ).to eq "2000/01/01 +12:00"

    # Chicago's still eating dinner, in the 'past' by 6 hours
    cond = DateCondition.new(value: { 'start_date' => Date.new(2000, 1, 1), 'timezone' => 'America/Chicago' }, operand: Condition::OPERANDS[:is_after])
    expect( Time.zone.now.in_time_zone("America/Chicago").to_s ).to eq "1999-12-31 18:00:00 -0600"
    expect( cond.comparable_start_date ).to eq "2000/01/01 +06:00"
  end

  it 'should handle eastern hemisphere timezones' do
    Time.zone = "Hawaii"
    Timecop.freeze( Time.zone.local(2000, 01, 01, 12, 00, 00) )
    expect( Time.zone.name ).to eq "Hawaii"
    expect( Time.zone.now.to_s ).to eq "2000-01-01 12:00:00 -1000"

    # Date conditions should ignore server timezone

    # Noon on January 1st in Hawaii
    cond = DateCondition.new(value: { 'start_date' => Date.new(2000, 1, 1), 'timezone' => 'Hawaii' }, operand: Condition::OPERANDS[:is_after])
    expect( cond.comparable_start_date ).to eq "2000/01/01 +02:00" # +2 is Hawaii timezone

    # China is already in the next day, but it should lock to UTC date
    cond = DateCondition.new(value: { 'start_date' => Date.new(2000, 1, 1), 'timezone' => 'Asia/Shanghai' }, operand: Condition::OPERANDS[:is_after])
    expect( cond.comparable_start_date ).to eq "2000/01/01 +20:00" # Shanghai timezone
  end

  it 'should not add daylight savings time in Arizonan timezones' do
    # Denver is in MDT
    cond = DateCondition.new(value: { 'start_date' => Date.new(2000, 7, 1), 'timezone' => 'America/Denver' }, operand: Condition::OPERANDS[:is_after])
    expect( cond.comparable_start_date ).to eq "2000/07/01 +06:00"
    # Arizona turns to midnight an hour later in the summer since it's in MST year-round
    cond = DateCondition.new(value: { 'start_date' => Date.new(2000, 7, 1), 'timezone' => 'America/Phoenix' }, operand: Condition::OPERANDS[:is_after])
    expect( cond.comparable_start_date ).to eq "2000/07/01 +05:00"
  end
end

describe ScriptGenerator, 'date compares work in all timezones' do
  let(:site) { double 'site', id: '1337', rules: [Rule.new], site_elements: double('site_elements', active: []) }
  let(:generator) { ScriptGenerator.new(site) }
  let(:rule) { site.rules.first }

  context 'with timezone given in western hemisphere' do
    let(:condition) {
      cond = DateCondition.new(value: { 'start_date' => Date.new(2000, 1, 1), 'timezone' => 'America/Denver' }, operand: Condition::OPERANDS[:is_after])
      cond.tap { rule.conditions << cond }
    }
    let(:sinon_denver) { 'sinon.useFakeTimers(new Date(2000, 0, 1).getTime());' } # 12am MST
    let(:sinon_chicago) { 'sinon.useFakeTimers(new Date(2000, 0, 1, 1).getTime());' } # 1am CST
    let(:sinon_la) { 'sinon.useFakeTimers(new Date(1999, 11, 31, 23).getTime());' } # 11pm PST 

    it 'returns correctly' do
      # the date in denver is our target
      result = phantom("TZ=America/Denver", sinon_denver, ['new Date()', '_HB.comparableDate(+5)'])
      expect(result[0]).to eq "Sat Jan 01 2000 00:00:00 GMT-0700 (MST)"
      expect(result[1]).to eq "2000/01/01 +05:00"

      target = condition.comparable_start_date
      expect(target).to eq "2000/01/01 +05:00"
      
      # It is on the date (2000/01/01) in Chicago; condition not met with >= time.
      result = phantom("TZ=America/Chicago", sinon_chicago, %{_HB.comparableDate(+5) >= "#{target}"})
      expect(result).to eq [ "true" ] # will always return as a string, it's console output

      # It is not on the date west of zone in Los Angeles; condition not met with <= time.
      result = phantom("TZ=America/Los_Angeles", sinon_la, ['new Date()',
                                                            '_HB.comparableDate(+5)', 
                                                            %{_HB.comparableDate(+5) >= "#{target}"}])
      expect(result).to eq [  "Fri Dec 31 1999 23:00:00 GMT-0800 (PST)",
                              "2000/01/01 +04:00",
                              "false" ]
    end
  end

  context 'with timezone given in eastern hemisphere' do
    let(:condition) {
      cond = DateCondition.new(value: { 'start_date' => Date.new(2000, 1, 1), 'timezone' => 'Asia/Tokyo' }, operand: Condition::OPERANDS[:is_after])
      cond.tap { rule.conditions << cond }
    }
    let(:sinon_tokyo) { 'sinon.useFakeTimers(new Date(2000, 0, 1).getTime());' }
    let(:sinon_shanghai) { 'sinon.useFakeTimers(new Date(1999, 11, 31, 23).getTime());' }

    it 'returns correctly' do
      # the date in japan is our target
      result = phantom("TZ=Asia/Tokyo", sinon_tokyo, ['new Date()', '_HB.comparableDate(+21)'])
      expect(result).to eq [  "Sat Jan 01 2000 00:00:00 GMT+0900 (JST)",
                              "2000/01/01 +21:00" ]

      target = condition.comparable_start_date
      expect(target).to eq "2000/01/01 +21:00"

      # It is on the date (2000/01/01) in Tokyo; condition not met with >= time.
      result = phantom("TZ=Asia/Tokyo", sinon_tokyo, %{_HB.comparableDate(+21) >= "#{target}"})
      expect(result).to eq [ "true" ] # will always return as a string, it's console output

      # It is not on the date west of zone in Shanghai; condition not met with <= time.
      result = phantom("TZ=Asia/Shanghai", sinon_shanghai, ['new Date()',
                                                            '_HB.comparableDate(+21)',
                                                            %{_HB.comparableDate(+21) >= "#{target}"}])
      expect(result).to eq [  "Fri Dec 31 1999 23:00:00 GMT+0800 (CST)",
                              "2000/01/01 +20:00",
                              "false" ]
    end
  end

  context 'condition does not pass at 11:59, does pass at midnight' do
    let(:fail_time) { 'sinon.useFakeTimers(new Date(1999, 11, 31, 23, 59, 59).getTime());' }
    let(:pass_time) { 'sinon.useFakeTimers(new Date(2000, 0, 1, 0, 0, 0).getTime());' }

    it 'with correct status' do
      # we want to show new yorkers a midnight hello bar
      condition = DateCondition.new(value: { 'start_date' => Date.new(2000, 1, 1), 'timezone' => 'America/New_York' }, operand: Condition::OPERANDS[:is_after])
      rule.conditions = [ condition ]

      generator.render.should include 'HB.comparableDate() >= "2000/01/01 +07:00"'

      result = phantom("TZ=America/New_York", fail_time, ['new Date()',
                                                          '_HB.comparableDate(+7)',
                                                          'HB.comparableDate(+7) >= "2000/01/01 +07:00"'])
      expect(result).to eq [ "Fri Dec 31 1999 23:59:59 GMT-0500 (EST)", "2000/01/01 +06:59", "false"]

      result = phantom("TZ=America/New_York", pass_time, ['new Date()',
                                                          '_HB.comparableDate(+7)',
                                                          'HB.comparableDate(+7) >= "2000/01/01 +07:00"'])
      expect(result).to eq [ "Sat Jan 01 2000 00:00:00 GMT-0500 (EST)", "2000/01/01 +07:00", "true" ]

      # in earlier timezone
      expect(phantom("TZ=America/Chicago", fail_time, 'HB.comparableDate(+7) >= "2000/01/01 +07:00"')).to eq ["false"]
      expect(phantom("TZ=America/Chicago", pass_time, 'HB.comparableDate(+7) >= "2000/01/01 +07:00"')).to eq ["true"]
    end
  end

  private

  # Accepts either js to execute as a string or a block (or a &:proc)
  # ex. env = TZ=America/Los_Angeles
  # ex. before = $ = jQuery;
  def phantom env, before, js=nil, &block
    js ||= block.call()
    js = Array(js) # convert to array, even if already array
    path = Rails.root.join('tmp/base.js')
    File.open(path, 'w+') do |f|
      f.write File.readlines(Rails.root.join('vendor/assets/javascripts/sinon.js')).join("")
      f.write generator.render
      f.write before
      js.each do |line|
        f.write "\nconsole.log(#{line});\n"
      end
      f.write "phantom.exit();"
    end
    `#{env} phantomjs #{path}`.split("\n").tap { FileUtils.rm(path) }
  end
end
