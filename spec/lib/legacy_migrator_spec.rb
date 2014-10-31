require 'spec_helper'

=begin
describe LegacyMigrator, '.migrate_sites_and_users_and_memberships' do
  let(:legacy_site) { double 'legacy_site', legacy_site_id: 44332211, id: 11223344, base_url: 'http://baller4ever.sho', account_id: 1, created_at: Time.parse('1875-01-30'), updated_at: Time.parse('1875-01-31'), script_installed_at: Time.now, generated_script: Time.now, attempted_generate_script: Time.now }

  context 'site migration' do
    before do
      LegacyMigrator::LegacySite.should_receive(:find_each).and_yield(legacy_site)
    end

    it 'creates a new site with LegacySite#legacy_site_id if present' do
      LegacyMigrator.stub :create_user_and_membership

      expect {
        LegacyMigrator.migrate_sites_and_users_and_memberships
      }.to change{ Site.exists?(legacy_site.legacy_site_id) }.from(false).to(true)
    end

    it 'creates a new site with LegacySite#id' do
      legacy_site.stub legacy_site_id: nil
      LegacyMigrator.stub :create_user_and_membership

      expect {
        LegacyMigrator.migrate_sites_and_users_and_memberships
      }.to change{ Site.exists?(legacy_site.id) }.from(false).to(true)
    end

    it 'creates a new site with LegacySite#created_at' do
      LegacyMigrator.stub :create_user_and_membership

      LegacyMigrator.migrate_sites_and_users_and_memberships

      Site.find(legacy_site.legacy_site_id).created_at.should == legacy_site.created_at
    end

    it 'creates a new site with LegacySite#updated_at' do
      LegacyMigrator.stub :create_user_and_membership

      LegacyMigrator.migrate_sites_and_users_and_memberships

      Site.find(legacy_site.legacy_site_id).updated_at.should == legacy_site.updated_at
    end

    it "sets the subscription for migrated sites to 'free plus'" do
      LegacyMigrator.stub :create_user_and_membership

      LegacyMigrator.migrate_sites_and_users_and_memberships

      site = Site.find(legacy_site.legacy_site_id)
      site.current_subscription.class.should == Subscription::FreePlus
    end
  end

  context 'user and membership migration' do
    before do
      LegacyMigrator::LegacySite.stub(:find_each).and_yield(legacy_site)
      legacy_user.stub legacy_user_id: 11223344, id: 44332211, email: "rand#{rand(10_0000)}-#{rand(10_000)}@email.com", original_created_at: Time.parse('1824-05-07')
    end

    let(:legacy_account) { double 'legacy_account', memberships: [legacy_membership] }
    let(:legacy_membership) { double 'legacy_membership', id: 1, user: legacy_user }
    let(:legacy_user) { LegacyMigrator::LegacyUser.new }

    before do
      LegacyMigrator::LegacyAccount.stub find: legacy_account
    end

    it 'does not create a user if it already exists' do
      User.stub :where => [User.new]

      expect {
        LegacyMigrator.migrate_sites_and_users_and_memberships
      }.to_not change(User, :count)
    end

    it 'skips creating a user if no legacy user can be found' do
      legacy_membership.stub user: nil

      expect {
        LegacyMigrator.migrate_sites_and_users_and_memberships
      }.to_not change(User, :count)
    end

    it 'skips creating a user if a legacy Wordpress user exists' do
      Hello::WordpressUser.stub email_exists?: true

      expect {
        LegacyMigrator.migrate_sites_and_users_and_memberships
      }.to_not change(User, :count)
    end

    it 'skips creating a site membership if no legacy user can be found' do
      legacy_membership.stub user: nil

      expect {
        LegacyMigrator.migrate_sites_and_users_and_memberships
      }.to_not change(SiteMembership, :count)
    end

    it 'creates a new user with the LegacyUser#legacy_user_id if it exists' do
      expect {
        LegacyMigrator.migrate_sites_and_users_and_memberships
      }.to change{ User.exists?(legacy_user.legacy_user_id) }.from(false).to(true)
    end

    it 'creates a new user with the LegacyUser#id if there is no legacy id' do
      legacy_user.stub legacy_user_id: nil

      expect {
        LegacyMigrator.migrate_sites_and_users_and_memberships
      }.to change{ User.exists?(legacy_user.id) }.from(false).to(true)
    end

    it 'creates a new user with the LegacyUser#original_created_at if present' do
      expect {
        LegacyMigrator.migrate_sites_and_users_and_memberships
      }.to change(User, :count).by(1)

      new_user = User.find(legacy_user.legacy_user_id)

      new_user.created_at.should == legacy_user.original_created_at
    end

    it 'creates a new user with the LegacyUser#created_at if no original_created_at is present' do
      legacy_user.stub original_created_at: nil, created_at: Time.parse('1971-12-19')
      LegacyMigrator.migrate_sites_and_users_and_memberships

      new_user = User.find(legacy_user.legacy_user_id)

      new_user.created_at.should == legacy_user.created_at
    end

    it 'creates a new user with the LegacyUser#updated_at' do
      legacy_user.stub updated_at: Time.parse('2007-10-23')
      LegacyMigrator.migrate_sites_and_users_and_memberships

      new_user = User.find(legacy_user.legacy_user_id)

      new_user.updated_at.should == legacy_user.updated_at
    end

    it 'associates the site and user with a new SiteMembership' do
      LegacyMigrator.migrate_sites_and_users_and_memberships

      new_user = User.find(legacy_user.legacy_user_id)
      new_site = Site.find(legacy_site.legacy_site_id)

      new_user.sites.should == [new_site]
    end

    it 'associates multiple sites with the correct user' do
      second_legacy_site = double 'legacy_site', legacy_site_id: 44332212, id: 11223344, base_url: 'http://baller4ever.sho', account_id: 1, created_at: Time.parse('1875-01-30'), updated_at: Time.parse('1875-01-31'), script_installed_at: Time.now, generated_script: Time.now, attempted_generate_script: Time.now
      LegacyMigrator::LegacySite.stub(:find_each).and_yield(legacy_site).and_yield(second_legacy_site)

      LegacyMigrator.migrate_sites_and_users_and_memberships

      migrated_user = User.find(legacy_user.legacy_user_id)

      migrated_user.sites.size.should == 2
    end
  end
end

describe LegacyMigrator, '.migrate_goals_to_rules' do
  fixtures :all

  let(:site) { sites(:zombo) }
  let(:start_date) { '2013-12-01' }
  let(:end_date) { '2014-06-05' }
  let(:legacy_goal) { double 'legacy_goal', id: 12345, site_id: legacy_site.id, data_json: {}, created_at: Time.parse('2000-01-31'), updated_at: Time.now, type: "Goals::DirectTraffic", priority: 1 }
  let(:legacy_site) { double 'legacy_site', id: 123 }
  let(:bar_settings) { { 'message' => 'goes here' } }
  let(:legacy_bar) { double 'legacy_bar', legacy_bar_id: 123, active?: true, created_at: Time.parse('2001-09-11'), updated_at: Time.now, target_segment: 'dv:computer', goal_id: legacy_goal.id, settings_json: bar_settings }
  let(:mobile_bar) { double 'legacy_bar', target_segment: nil, settings_json: { 'target' => 'dv:mobile' }}

  before do
    Rule.destroy_all
    legacy_goal.stub bars: [legacy_bar]
    Site.stub(:find_each).and_yield(site)
    LegacyMigrator::LegacyGoal.stub where: [legacy_goal]
  end

  context 'creating rules' do
    it 'should create a rule from a corresponding goal for a site' do
      expect {
        LegacyMigrator.migrate_goals_to_rules
      }.to change(Rule, :count).by(1)

      rule = Rule.find(legacy_goal.id)

      rule.id.should == legacy_goal.id
      rule.site_id.should == site.id
      rule.created_at.to_time.utc.to_s.should == legacy_goal.created_at.to_time.utc.to_s
      rule.updated_at.to_time.utc.to_s.should == legacy_goal.updated_at.to_time.utc.to_s
    end

    it 'creates a new rule for every legacy goal that exists' do
      legacy_goal2 = legacy_goal.clone
      legacy_goal2 = double 'legacy_goal', id: 54321, site_id: legacy_site.id, data_json: {}, created_at: Time.parse('2000-01-31'), updated_at: Time.now, type: "Goals::DirectTraffic", priority: 1, data_json: {'start_date' => '01/01/2014'}
      legacy_bar2 = double 'legacy_bar', legacy_bar_id: 314, active?: true, created_at: Time.parse('2001-09-11'), updated_at: Time.now, target_segment: 'dv:computer', goal_id: legacy_goal.id, settings_json: bar_settings
      legacy_goal2.stub bars: [legacy_bar2]

      LegacyMigrator::LegacyGoal.stub where: [legacy_goal, legacy_goal2]

      expect {
        LegacyMigrator.migrate_goals_to_rules
      }.to change(Rule, :count).by(2)
    end

    it 'creates a default rule for sites that dont have legacy goals' do
      LegacyMigrator::LegacyGoal.stub where: []

      site.should_receive(:create_default_rule)

      LegacyMigrator.migrate_goals_to_rules
    end

    it 'creates a new DateCondition if start_date is specified' do
      legacy_goal.stub data_json: { 'start_date' => start_date }

      expect {
        LegacyMigrator.migrate_goals_to_rules
      }.to change(Condition, :count).by(1)
    end

    it 'creates a new DateRule if end_date is specified' do
      legacy_goal.stub data_json: { 'end_date' => end_date }

      expect {
        LegacyMigrator.migrate_goals_to_rules
      }.to change(Condition, :count).by(1)
    end

    it 'creates a new DateRule with the proper values when both start_date and end_date are specified' do
      legacy_goal.stub data_json: { 'start_date' => start_date, 'end_date' => end_date }

      LegacyMigrator.migrate_goals_to_rules

      condition = Rule.find(legacy_goal.id).conditions.first

      condition.value.should == [start_date, end_date]
    end

    it 'creates a new UrlRule if include_urls is specified' do
      legacy_goal.stub data_json: { 'include_urls' => ['http://url.com'] }

      expect {
        LegacyMigrator.migrate_goals_to_rules
      }.to change(Condition, :count).by(1)
    end

    it 'creates a new UrlRule if exclude_urls is specified' do
      legacy_goal.stub data_json: { 'exclude_urls' => ['http://url.com'] }

      expect {
        LegacyMigrator.migrate_goals_to_rules
      }.to change(Condition, :count).by(1)
    end

    it 'creates a new UrlRule if both exclude_urls and are specified' do
      data = { 'exclude_urls' => ['http://exclude.com'], 'include_urls' => ['http://include.com'] }
      legacy_goal.stub data_json: data

      LegacyMigrator.migrate_goals_to_rules

      conditions = Rule.find(legacy_goal.id).conditions

      conditions.find{|condition| condition.operand == 'includes' }.value.should == 'http://include.com'
      conditions.find{|condition| condition.operand == 'does_not_include' }.value.should == 'http://exclude.com'
    end

    it 'creates both a DateRule and a UrlRule for every url present when start_date and include_urls are specified' do
      data = { 'exclude_urls' => ['http://include.com', 'http://another.com'], 'include_urls' => ['http://exclude.com'], 'start_date' => '01/01/2001', 'end_date' => '12/12/2012' }
      legacy_goal.stub data_json: data

      expect {
        LegacyMigrator.migrate_goals_to_rules
      }.to change(Condition, :count).by(4)
    end

    it 'sets the rule name to Everyone when there are zero conditions for a rule' do
      legacy_goal.stub data_json: {}

      LegacyMigrator.migrate_goals_to_rules

      rule = Rule.find(legacy_goal.id)

      rule.name.should == 'Everyone'
    end

    it 'updates the rule name when there are more than 1 conditions for a rule' do
      data = { 'exclude_urls' => ['http://exclude.com'], 'start_date' => '01/01/2014' }
      legacy_goal.stub data_json: data

      LegacyMigrator.migrate_goals_to_rules

      rule = Rule.find(legacy_goal.id)

      rule.name.should == 'Rule 1'
    end

    context "combining goals into the same rule" do
      let(:legacy_bar2) { double('legacy_bar', legacy_bar_id: 1234, active?: true, created_at: Time.parse('2001-09-11'), updated_at: Time.now, target_segment: 'dv:computer', goal_id: legacy_goal.id, settings_json: bar_settings) }
      let(:legacy_goal2) {  double('legacy_goal', id: 12346, site_id: legacy_site.id, data_json: {}, created_at: Time.parse('2000-01-31'), updated_at: Time.now, type: "Goals::DirectTraffic", priority: 1, bars: [legacy_bar2]) }

      before do
        LegacyMigrator::LegacyGoal.stub where: [legacy_goal, legacy_goal2]
      end

      it "merges goals when the conditions match" do
        data = { 'exclude_urls' => ['http://exclude.com'], 'start_date' => '01/01/2014' }
        legacy_goal.stub data_json: data
        legacy_goal2.stub data_json: data

        LegacyMigrator.migrate_goals_to_rules

        rules = Rule.where(:id => [legacy_goal.id, legacy_goal2.id])

        rules.count.should == 1
        rules.first.site_elements.count.should == 2
      end

      it "does not merge goals when the conditions are different" do
        legacy_goal.stub data_json: { 'exclude_urls' => ['http://exclude.com'] }
        legacy_goal2.stub data_json: { 'start_date' => '01/01/2014' }

        LegacyMigrator.migrate_goals_to_rules

        rules = Rule.where(:id => [legacy_goal.id, legacy_goal2.id])

        rules.count.should == 2
        rules[0].site_elements.count.should == 1
        rules[1].site_elements.count.should == 1
      end
    end

    context 'when the goal has a bar that is targeted to mobile users' do
      let(:legacy_goal) { double 'legacy_goal', id: 12345, site_id: legacy_site.id, data_json: { 'start_date' => '01/01/2012' }, created_at: Time.parse('2000-01-31'), updated_at: Time.now, type: "Goals::DirectTraffic", priority: 1 }
      let(:mobile_bar) { double('legacy_bar', legacy_bar_id: 1234, active?: true, created_at: Time.parse('2001-09-11'), updated_at: Time.now, target_segment: 'dv:mobile', goal_id: legacy_goal.id, settings_json: {}) }
      let(:non_mobile_bar) { double('legacy_bar', legacy_bar_id: 1235, active?: true, created_at: Time.parse('2001-09-11'), updated_at: Time.now, target_segment: 'dv:computer', goal_id: legacy_goal.id, settings_json: {}) }

      before do
        Rule.destroy_all
        Site.stub(:find_each).and_yield(site)
        LegacyMigrator::LegacyGoal.stub where: [legacy_goal]
        legacy_goal.stub bars: [mobile_bar, non_mobile_bar]
      end

      it 'only creates 1 rule if there is only 1 mobile bar' do
        legacy_goal.stub bars: [mobile_bar]

        expect {
          LegacyMigrator.migrate_goals_to_rules
        }.to change(Rule, :count).by(1)
      end

      it 'creates 2 rules when there are both mobile and non mobile bars' do
        expect {
          LegacyMigrator.migrate_goals_to_rules
        }.to change(Rule, :count).by(2)
      end

      it 'sets the non-mobile rule ID to the legacy goal ID when both mobile and non-mobile rules are created' do
        LegacyMigrator.migrate_goals_to_rules

        Rule.find(legacy_goal.id).conditions.size.should == 1
      end

      it 'adds the device condition to the mobile rule' do
        legacy_goal.stub bars: [mobile_bar]

        LegacyMigrator.migrate_goals_to_rules

        Rule.find(legacy_goal.id).conditions.size.should == 2
      end
    end
  end

  context 'creating site elements from legacy bars' do
    it 'creates a new bar for every legacy bar that exists' do
      legacy_goal2 = legacy_goal.clone
      legacy_goal2 = double 'legacy_goal', id: 54321, site_id: legacy_site.id, data_json: {}, created_at: Time.parse('2000-01-31'), updated_at: Time.now, type: "Goals::DirectTraffic", priority: 1
      legacy_bar2 = double 'legacy_bar', legacy_bar_id: 314, active?: true, created_at: Time.parse('2001-09-11'), updated_at: Time.now, target_segment: 'dv:computer', goal_id: legacy_goal.id, settings_json: bar_settings
      legacy_goal2.stub bars: [legacy_bar2]

      LegacyMigrator::LegacyGoal.stub where: [legacy_goal, legacy_goal2]

      expect {
        LegacyMigrator.migrate_goals_to_rules
      }.to change(SiteElement, :count).by(2)
    end

    it 'associates all newly created bars with the new rule' do
      legacy_goal.stub bars: [legacy_bar]
      LegacyMigrator::LegacyGoal.stub where: [legacy_goal]

      LegacyMigrator.migrate_goals_to_rules

      rule = Rule.find(legacy_goal.id)

      rule.site_elements.count.should == 1
    end
  end

  it 'standardizes the legacy goal type' do
    LegacyMigrator.migrate_goals_to_rules

    bar = Rule.find(legacy_goal.id).site_elements.first

    bar.element_subtype.should == 'traffic'
  end

  it 'standardizes the legacy goal type for social bars' do
    legacy_goal.stub(:type => "Goals::SocialMedia")
    legacy_goal.stub(:data_json => {"interaction" => "tweet_on_twitter"})

    LegacyMigrator.migrate_goals_to_rules

    bar = Rule.find(legacy_goal.id).site_elements.first

    bar.element_subtype.should == 'social/tweet_on_twitter'
  end

  it 'copies over legacy goal social settings to bar' do
    legacy_goal.stub data_json: { 'buffer_message' => 'such buffer. wow.' }

    LegacyMigrator.migrate_goals_to_rules

    bar = Rule.find(legacy_goal.id).site_elements.first

    bar.settings.should == { 'buffer_message' => 'such buffer. wow.' }
  end
end

describe LegacyMigrator, ".migrate_identities" do
  let(:legacy_id) { double "legacy_id", id: 12345, site_id: legacy_site.id, created_at: Time.parse("2000-01-31"), updated_at: Time.now, provider: "provider", credentials: "credentials", extra: "extra", embed_code: "embed_code" }
  let(:legacy_site) { double "legacy_site", id: 123 }

  before do
    Site.stub :exists? => true
    LegacyMigrator::LegacyIdentity.should_receive(:find_each).and_yield(legacy_id)
  end

  it "migrates all attributes from legacy identity" do
    Identity.should_receive(:create!).with(
      id: legacy_id.id,
      site_id: legacy_id.site_id,
      provider: legacy_id.provider,
      credentials: legacy_id.credentials,
      extra: legacy_id.extra,
      created_at: legacy_id.created_at,
      updated_at: legacy_id.updated_at
    )

    LegacyMigrator.migrate_identities
  end
end

describe LegacyMigrator, ".migrate_goals_to_contact_lists" do
  let(:legacy_email_goal) { double "legacy_email_goal", id: 12345, site_id: legacy_site.id, data_json: {}, created_at: Time.parse("2000-01-31"), updated_at: Time.now, type: "Goals::CollectEmail", priority: 1 }
  let(:legacy_traffic_goal) { double "legacy_traffic_goal", id: 12346, site_id: legacy_site.id, data_json: {}, created_at: Time.parse("2000-01-31"), updated_at: Time.now, type: "Goals::DirectTraffic", priority: 1 }
  let(:legacy_site) { double "legacy_site", id: 123 }
  let(:legacy_identity) { double "identity", embed_code: "old embed code" }
  let(:legacy_id_int) { double "legacy_id_int", id: 123, identity_id: 4113, data: {"remote_name" => "list name"}, created_at: 1.month.ago, updated_at: 1.day.ago, identity: legacy_identity }

  before do
    Site.stub :exists? => true
    LegacyMigrator::LegacyGoal.should_receive(:find_each).and_yield(legacy_email_goal).and_yield(legacy_traffic_goal)
    LegacyMigrator::LegacyIdentityIntegration.stub :where => []
  end

  it "creates a contact list only for CollectEmail goals" do
    expect {
      LegacyMigrator.migrate_contact_lists
    }.to change(ContactList, :count).by(1)

    ContactList.find_by_id(legacy_email_goal.id).should_not be_nil
  end

  it "creates the property attributes for goals without a LegacyIdentityIntegration" do
    ContactList.should_receive(:create!).with(hash_including(
      id: legacy_email_goal.id,
      site_id: legacy_email_goal.site_id,
      name: "List #{legacy_email_goal.id}",
      created_at: legacy_email_goal.created_at,
      updated_at: legacy_email_goal.updated_at
    ))

    LegacyMigrator.migrate_contact_lists
  end

  it "creates the property attributes for goals without a LegacyIdentityIntegration" do
    LegacyMigrator::LegacyIdentityIntegration.stub :where => [legacy_id_int]
    Identity.stub :exists? => true

    ContactList.should_receive(:create!).with(hash_including(
      identity_id: legacy_id_int.identity_id,
      data: legacy_id_int.data.merge(embed_code: legacy_identity.embed_code),
      name: legacy_id_int.data["remote_name"],
      created_at: legacy_id_int.created_at,
      updated_at: legacy_id_int.updated_at
    ))

    LegacyMigrator.migrate_contact_lists
  end
end

describe LegacyMigrator, '.migrate_site_timezones' do
  fixtures :all

  let(:legacy_site) { double 'legacy_site', legacy_site_id: 44332211, id: 11223344, base_url: 'http://baller4ever.sho', account_id: 1, created_at: Time.parse('1875-01-30'), updated_at: Time.parse('1875-01-31'), script_installed_at: Time.now, generated_script: Time.now, attempted_generate_script: Time.now }
  let(:site) { sites(:zombo) }

  before do
    LegacyMigrator::LegacySite.stub(:find_each).and_yield(legacy_site)
    Site.stub find: site
  end

  it "doesnt set a site's timezone if the goals had no timezone" do
    legacy_goal = double 'legacy goal', data_json: {}
    LegacyMigrator::LegacyGoal.stub where: [legacy_goal]

    ::Site.should_not_receive(:find)

    LegacyMigrator.migrate_site_timezones
  end

  it "sets the site's timezone if there is only 1 goal with a timezone" do
    goal = double 'legacy goal', data_json: { 'dates_timezone' => '(GMT+HH:MM) best timezone evar' }
    LegacyMigrator::LegacyGoal.stub where: [goal]

    LegacyMigrator.migrate_site_timezones

    site.reload.timezone.should == 'best timezone evar'
  end

  it "sets the site's timezone if there is only 1 timezone for multiple goals" do
    goal = double 'legacy goal', data_json: { 'dates_timezone' => '(GMT+HH:MM) best timezone evar' }
    LegacyMigrator::LegacyGoal.stub where: [goal, goal]

    LegacyMigrator.migrate_site_timezones

    site.reload.timezone.should == 'best timezone evar'
  end

  it "sets the site's timezone to the first goals timezone for multiple goals" do
    goal = double 'legacy goal', data_json: { 'dates_timezone' => '(GMT+HH:MM) first timezone' }
    goal2 = double 'legacy goal', data_json: { 'dates_timezone' => '(GMT+HH:MM) second timezone' }
    LegacyMigrator::LegacyGoal.stub where: [goal, goal2]

    LegacyMigrator.migrate_site_timezones

    site.reload.timezone.should == 'first timezone'

    LegacyMigrator::LegacyGoal.stub where: [goal2, goal]

    LegacyMigrator.migrate_site_timezones

    site.reload.timezone.should == 'second timezone' # sanity check
  end
end

describe LegacyMigrator, '#timezone_for_goal' do
  let(:goal) { double 'legacy_goal', data_json: {} }

  it 'returns nil if calling #date_json throws an error' do
    goal.stub(:data_json).and_raise(StandardError)

    LegacyMigrator.timezone_for_goal(goal).should be_nil
  end

  it 'returns nil if the timezone is nil' do
    LegacyMigrator.timezone_for_goal(goal).should be_nil
  end

  it 'returns nil if the timezone is "visitor"' do
    goal.data_json['dates_timezone'] = 'visitor'

    LegacyMigrator.timezone_for_goal(goal).should be_nil
  end

  it 'returns nil if the timezone is "false"' do
    goal.data_json['dates_timezone'] = 'false'

    LegacyMigrator.timezone_for_goal(goal).should be_nil
  end

  it 'returns the timezone string without the offset' do
    goal.data_json['dates_timezone'] = '(GMT-06:00) Central Time (US & Canada)'

    LegacyMigrator.timezone_for_goal(goal).should == 'Central Time (US & Canada)'
  end
end

describe LegacyMigrator, '#bar_is_mobile?' do
  it 'returns true if legacy bar#target_segment equals the mobile code' do
    legacy_bar = double 'legacy_bar', target_segment: 'dv:mobile'

    LegacyMigrator.bar_is_mobile?(legacy_bar).should be_true
  end

  it 'returns true if legacy bar has a mobile json setting' do
    legacy_bar = double 'legacy_bar', target_segment: nil, settings_json: { 'target' => 'dv:mobile' }

    LegacyMigrator.bar_is_mobile?(legacy_bar).should be_true
  end

  it 'returns false if both legacy bar#target_segment and no mobile json setting is set' do
    legacy_bar = double 'legacy_bar', target_segment: nil, settings_json: {}

    LegacyMigrator.bar_is_mobile?(legacy_bar).should be_false
  end
end
=end
