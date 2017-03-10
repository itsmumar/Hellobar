require_relative 'test_helper'

describe 'migration of legacy rules to goals' do
  it 'migrates basic attributes' do
    site = Site.find(2155)
    legacy_site = LegacyMigrator::LegacySite.find(site.id)
    goal = legacy_site.goals.first
    rule = site.rules.find(goal.id)

    assert_equal goal.id, rule.id
    assert_equal goal.created_at, rule.created_at
    assert_equal goal.updated_at, rule.updated_at
  end

  it 'creates default rules for sites that had no 2.0 goals' do
    site = Site.where(url: 'http://zombo.com').first
    legacy_site = LegacyMigrator::LegacySite.find(site.id)

    assert_equal 0, legacy_site.goals.count
    assert_equal 3, site.rules.count
  end

  it 'creates a DateCondition if end_date is specified on goal' do
    rule = Rule.find(397)
    goal = LegacyMigrator::LegacyGoal.find(rule.id)
    condition = rule.conditions.first

    assert goal.data_json['end_date'].present?
    assert goal.data_json['start_date'].nil?

    assert_equal 'DateCondition', condition.segment
    assert_equal 'before', condition.operand
    assert_equal goal.data_json['end_date'], condition.value
  end

  it 'creates a DateCondition if end_date and start_date are specified on goal' do
    rule = Rule.find(398)
    goal = LegacyMigrator::LegacyGoal.find(rule.id)
    condition = rule.conditions.first

    assert goal.data_json['end_date'].present?
    assert goal.data_json['start_date'].present?

    assert_equal 'DateCondition', condition.segment
    assert_equal 'between', condition.operand
    assert_equal [goal.data_json['start_date'], goal.data_json['end_date']], condition.value
  end

  it 'creates a UrlRule if include_urls is specified on goal' do
    rule = Rule.find(405)
    goal = LegacyMigrator::LegacyGoal.find(rule.id)
    condition = rule.conditions.first

    assert goal.data_json['include_urls'].present?

    assert_equal 'UrlCondition', condition.segment
    assert_equal 'is', condition.operand
    assert_equal goal.data_json['include_urls'], condition.value
  end

  it 'creates a UrlRule if exclude_urls is specified on goal' do
    rule = Rule.find(388)
    goal = LegacyMigrator::LegacyGoal.find(rule.id)
    condition = rule.conditions.first

    assert goal.data_json['exclude_urls'].present?

    assert_equal 'UrlCondition', condition.segment
    assert_equal 'is_not', condition.operand
    assert_equal goal.data_json['exclude_urls'], condition.value
  end

  it 'sets the rule name to Everyone when there are zero conditions for a rule' do
    site = Site.where(url: 'http://zombo.com').first
    rule = site.rules.first

    assert_equal 0, rule.conditions.count
    assert_equal 'Everyone', rule.name
  end

  it 'sets an appropriate name when for mobile rules' do
    rule = Rule.find(650)

    assert_equal 1, rule.conditions.count
    assert_equal 'mobile', rule.conditions.first.value
    assert rule.name =~ /Device Rule #\d+/
  end

  it 'sets an appropriate name when for rules with any conditions' do
    rule = Rule.find(376)

    assert_equal 1, rule.conditions.count
    assert_equal 'UrlCondition', rule.conditions.first.segment
    assert rule.name =~ /Page URL Rule #\d+/
  end

  it 'merges goals when the conditions are the same' do
    legacy_site = LegacyMigrator::LegacySite.find(2154)
    goal_conditions = legacy_site.goals.map { |g| g.data_json.slice('include_urls', 'exclude_urls', 'start_date', 'end_date') }

    assert_equal 2, legacy_site.goals.count
    assert_equal goal_conditions[0], goal_conditions[1]

    assert_equal 1, Rule.where(id: legacy_site.goals.map(&:id)).count
  end

  it 'merges goals that have no conditions' do
    site = Site.find(2012)
    assert_equal 3, site.rules.count
    assert_equal 'Everyone', site.rules.first.name
  end

  it 'names rules based on their ordinality within rules of that type belonging to the same site' do
    site = Site.find(2155)
    assert_equal ['Everyone', 'Device Rule #1'], site.rules.map(&:name)
  end

  it 'creates all valid conditions' do
    Condition.all.each do |condition|
      assert condition.valid?
    end
  end
end
