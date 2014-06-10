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
end
