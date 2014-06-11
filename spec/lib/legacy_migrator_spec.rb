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

describe LegacyMigrator, '.migrate_goals_to_rule_sets' do
  let(:start_date) { '2013-12-01' }
  let(:end_date) { '2014-06-05' }
  let(:legacy_goal) { double 'legacy_goal', id: 12345, site_id: legacy_site.id, data_json: { 'start_date' => start_date, 'end_date' => end_date, 'dates_timezone' => '(GMT-06:00) Central Time (US & Canada)' }, created_at: Time.parse('2000-01-31'), updated_at: Time.now, type: "Goals::DirectTraffic" }
  let(:legacy_site) { double 'legacy_site', id: 123 }
  let(:bar_settings) { { 'message' => 'goes here' } }
  let(:legacy_bar) { double 'legacy_bar', legacy_bar_id: 123, active?: true, created_at: Time.parse('2001-09-11'), updated_at: Time.now, target_segment: 'dv:computer', goal_id: 'legacy_goal.id', settings_json: bar_settings }

  before do
    Site.stub :exists? => true
    legacy_goal.stub bars: [legacy_bar]
    LegacyMigrator::LegacyGoal.should_receive(:find_each).and_yield(legacy_goal)
  end

  it 'doesnt create a new ruleset if the goal belongs to a site that doesnt exist' do
    Site.stub :exists? => false

    expect {
      LegacyMigrator.migrate_goals_to_rule_sets
    }.to_not change(RuleSet, :count)
  end

  it 'creates a new rule set with the proper attributes' do
    expect {
      LegacyMigrator.migrate_goals_to_rule_sets
    }.to change(RuleSet, :count).by(1)

    rule_set = RuleSet.find(legacy_goal.id)

    rule_set.id.should == legacy_goal.id
    rule_set.site_id.should == legacy_site.id
    rule_set.start_date.to_s.should == DateTime.parse(start_date + " 00:00:00 (GMT-06:00) Central Time (US & Canada)").to_time.utc.to_s
    rule_set.end_date.to_s.should == DateTime.parse(end_date + " 23:59:59 (GMT-06:00) Central Time (US & Canada)").to_time.utc.to_s
    rule_set.include_urls.should == legacy_goal.data_json['include_urls']
    rule_set.exclude_urls.should == legacy_goal.data_json['exclude_urls']
    rule_set.created_at.to_s.should == legacy_goal.created_at.to_time.utc.to_s
    rule_set.updated_at.to_s.should == legacy_goal.updated_at.to_time.utc.to_s
  end

  it 'creates a new bar for every legacy bar that exists' do
    expect {
      LegacyMigrator.migrate_goals_to_rule_sets
    }.to change(Bar, :count).by(1)
  end

  it 'associates all newly created bars with the new rule set' do
    LegacyMigrator.migrate_goals_to_rule_sets

    RuleSet.find(legacy_goal.id).bars.count.should == 1
  end

  it 'standardizes the legacy goal type' do
    LegacyMigrator.migrate_goals_to_rule_sets

    bar = RuleSet.find(legacy_goal.id).bars.first

    bar.goal.should == 'DirectTraffic'
  end
end
