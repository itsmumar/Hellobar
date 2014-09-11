require 'spec_helper'

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
  end

  context 'user and membership migration' do
    before do
      LegacyMigrator::LegacySite.should_receive(:find_each).and_yield(legacy_site)
      legacy_user.stub legacy_user_id: 11223344, id: 44332211, email: "rand#{rand(10_0000)}-#{rand(10_000)}@email.com", original_created_at: Time.parse('1824-05-07')
    end

    let(:legacy_account) { double 'legacy_account', memberships: [legacy_membership] }
    let(:legacy_membership) { double 'legacy_membership', id: 1, user: legacy_user }
    let(:legacy_user) { LegacyMigrator::LegacyUser.new }

    before do
      LegacyMigrator::LegacyAccount.stub find: legacy_account
    end

    it 'does not create a user if it already exists' do
      User.stub :exists? => true

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

  before do
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
      rule.site_id.should == legacy_site.id
      rule.created_at.to_time.utc.to_s.should == legacy_goal.created_at.to_time.utc.to_s
      rule.updated_at.to_time.utc.to_s.should == legacy_goal.updated_at.to_time.utc.to_s
    end

    it 'creates a new rule for every legacy goal that exists' do
      legacy_goal2 = legacy_goal.clone
      legacy_goal2 = double 'legacy_goal', id: 54321, site_id: legacy_site.id, data_json: {}, created_at: Time.parse('2000-01-31'), updated_at: Time.now, type: "Goals::DirectTraffic", priority: 1
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

      condition.value.should == { 'start_date' => DateTime.parse(start_date + " 00:00:00"), 'end_date' => DateTime.parse(end_date + " 23:59:59") }
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

      conditions.find{|condition| condition.include_url? }.value.should == 'http://include.com'
      conditions.find{|condition| !condition.include_url? }.value.should == 'http://exclude.com'
    end

    it 'creates both a DateRule and a UrlRule for every url present when start_date and include_urls are specified' do
      data = { 'exclude_urls' => ['http://include.com', 'http://another.com'], 'include_urls' => ['http://exclude.com'], 'start_date' => '01/01/2001', 'end_date' => '12/12/2012' }
      legacy_goal.stub data_json: data

      expect {
        LegacyMigrator.migrate_goals_to_rules
      }.to change(Condition, :count).by(4)
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

=begin
=end
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
  let(:legacy_id_int) { double "legacy_id_int", id: 123, identity_id: 4113, data: {"remote_name" => "list name"}, last_synced_at: 1.week.ago, created_at: 1.month.ago, updated_at: 1.day.ago, identity: legacy_identity }

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
      last_synced_at: legacy_id_int.last_synced_at,
      created_at: legacy_id_int.created_at,
      updated_at: legacy_id_int.updated_at
    ))

    LegacyMigrator.migrate_contact_lists
  end
end
