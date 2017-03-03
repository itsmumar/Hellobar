require_relative 'test_helper'

describe 'migration of bars to site elements' do
  describe 'mobile bars' do
    before do
      @bar = LegacyMigrator::LegacyBar.find(1715)
    end

    it 'creates a rule for migrated mobile bars' do
      site = Site.find(@bar.goal.site.id)
      condition = site.rules.map(&:conditions).flatten.find{|c| c.value == 'mobile'}

      assert_equal 'dv:mobile', @bar.settings_json['target']
      assert_equal 'mobile', condition.value
      assert_equal 'is', condition.operand
    end

    it 'creates two rules if there is a mobile and non-mobile bar under the same goal' do
      goal = @bar.goal
      site = Site.find(goal.site.id)

      assert_equal 2, goal.bars.count
      assert_equal 2, site.rules.count
    end
  end

  it 'creates a site_element for each legacy bar with a goal and a site' do
    count = LegacyMigrator::LegacyBar.all.select{|b| b.goal.present? && b.goal.site.present?}.count
    assert_equal count, SiteElement.count
  end

  it 'creates the correct type of site element for traffic bars' do
    element = SiteElement.find(1412)
    bar = LegacyMigrator::LegacyBar.find(element.id)

    assert_equal 'Goals::DirectTraffic', bar.goal.type
    assert_equal 'traffic', element.element_subtype
  end

  it 'creates the correct type of site element for email bars' do
    element = SiteElement.find(1479)
    bar = LegacyMigrator::LegacyBar.find(element.id)

    assert_equal 'Goals::CollectEmail', bar.goal.type
    assert_equal 'email', element.element_subtype
  end

  it 'creates the correct type of site element for social bars' do
    element = SiteElement.find(1651)
    bar = LegacyMigrator::LegacyBar.find(element.id)

    assert_equal 'Goals::SocialMedia', bar.goal.type
    assert_equal 'tweet_on_twitter', bar.goal.data_json['interaction']
    assert_equal 'social/tweet_on_twitter', element.element_subtype
  end

  it 'migrates social settings correctly' do
    element = SiteElement.find(1651)
    bar = LegacyMigrator::LegacyBar.find(element.id)

    assert_equal bar.goal.data_json['url_to_tweet'], element.settings['url_to_tweet']
    assert_equal bar.goal.data_json['message_to_tweet'], element.settings['message_to_tweet']
  end
end
