require_relative 'test_helper'

describe 'migration of bars to site elements' do
  it 'migrates basic attributes' do
    id = Identity.find(76)
    legacy_id = LegacyMigrator::LegacyIdentity.find(id.id)

    assert_equal legacy_id.provider, id.provider
    assert_equal legacy_id.credentials, id.credentials
    assert_equal legacy_id.extra, id.extra
  end
end
