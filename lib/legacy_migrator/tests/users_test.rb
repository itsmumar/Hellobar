require_relative 'test_helper'

describe 'migration of legacy users' do
  before do
    @site = Site.where(url: 'http://zombo.com').first
    @legacy_site = LegacyMigrator::LegacySite.find(@site.id)
    @user = @site.owners.first
    @legacy_user = LegacyMigrator::LegacyUser.find_by_email(@user.email)
  end

  it 'migrates basic attributes' do
    assert_equal @legacy_user.email, @user.email
    assert_equal @legacy_user.created_at, @user.created_at
    assert_equal @legacy_user.updated_at, @user.updated_at
  end

  it 'migrates memberships' do
    assert SiteMembership.where(site_id: @legacy_site.id, user_id: @legacy_site.account.users.first.id).first.present?
    assert_equal @legacy_site.account.users.first.id, @site.owners.first.id
  end

  it 'associates multiple sites with the correct user' do
    email = 'wootie@polymathic.me'
    wootie = User.find_by_email(email)
    legacy_wootie = LegacyMigrator::LegacyUser.find_by_email(email)

    num_sites = legacy_wootie.accounts.first.sites.count

    assert num_sites > 1
    assert_equal num_sites, wootie.sites.count
  end
end
