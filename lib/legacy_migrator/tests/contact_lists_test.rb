require_relative 'test_helper'

describe 'migration of goals to contact lists' do
  it 'creates a contact list for CollectEmail goals' do
    goal = LegacyMigrator::LegacyGoal.find(409)
    list = ContactList.find(goal.id)

    assert_equal 'Goals::CollectEmail', goal.type
    assert_equal goal.site_id, list.site_id
    assert_equal goal.created_at, list.created_at
    assert_equal goal.updated_at, list.updated_at
  end

  it 'creates a contact list and identity for CollectEmail goals with legacy identities' do
    goal = LegacyMigrator::LegacyGoal.find(469)
    legacy_int = LegacyMigrator::LegacyIdentityIntegration.where(integrable_id: goal.id).first
    legacy_id = LegacyMigrator::LegacyIdentity.find(legacy_int.identity_id)

    list = ContactList.find(goal.id)
    identity = list.identity

    assert_equal legacy_id.provider, identity.provider
    assert_equal legacy_id.credentials, identity.credentials
    assert_equal legacy_id.extra, identity.extra
  end

  it 'names contact lists based on ordinality' do
    site = Site.find(1987)
    names = site.contact_lists.map(&:name)

    assert_equal ['My Contacts', 'My Contacts 2', 'My Contacts 3'].sort, names.sort
  end

  it 'uses remote name for contact list if available' do
    list = ContactList.find(469)
    goal = LegacyMigrator::LegacyGoal.find(list.id)
    integration = LegacyMigrator::LegacyIdentityIntegration.where(integrable_id: goal.id).first

    assert_equal integration.data['remote_name'], list.name
  end
end
