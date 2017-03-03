require_relative 'test_helper'

describe 'migration of legacy sites' do
  before do
    @site = Site.where(url: 'http://zombo.com').first
    @legacy_site = LegacyMigrator::LegacySite.find(@site.id)
  end

  it 'migrates basic attributes' do
    assert_equal @legacy_site.base_url, @site.url
    assert_equal @legacy_site.created_at, @site.created_at
    assert_equal @legacy_site.updated_at, @site.updated_at
  end

  it 'gives sites a read and write key' do
    assert @site.read_key.present?
    assert @site.write_key.present?
  end

  it 'sets up migrated sites with a FreePlus-level subscription' do
    assert_equal Subscription::FreePlus, @site.current_subscription.class
  end

  it 'leaves the timezone blank if no legacy goal had a timezone' do
    assert !@legacy_site.goals.any?{|g| g.data_json['dates_timezone'].present?}
    assert @site.timezone.nil?
  end

  it 'uses the timezone from legacy site if present' do
    site = Site.find(1980)
    legacy_site = LegacyMigrator::LegacySite.find(site.id)
    timezone = legacy_site.goals.find{|g| g.data_json['dates_timezone'].present?}.data_json['dates_timezone']

    assert timezone.include?(site.timezone)
  end

  it 'migrates the email digest opt-in flag when true' do
    site = Site.find(2149)
    legacy_site = LegacyMigrator::LegacySite.find(site.id)

    assert_equal '1', legacy_site.settings_json['email_digest']
    assert_equal true, site.opted_in_to_email_digest
  end

  it 'migrates the email digest opt-in flag when false' do
    site = Site.find(2022)
    legacy_site = LegacyMigrator::LegacySite.find(site.id)

    assert_equal '0', legacy_site.settings_json['email_digest']
    assert_equal false, site.opted_in_to_email_digest
  end

  it 'migrates all sites' do
    assert_equal LegacyMigrator::LegacySite.count, Site.count
  end
end
