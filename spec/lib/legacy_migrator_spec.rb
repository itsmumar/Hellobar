describe LegacyMigrator, '#timezone_for_goal' do
  let(:goal) { double 'legacy_goal', data_json: {} }

  it 'returns nil if calling #date_json throws an error' do
    allow(goal).to receive(:data_json).and_raise(StandardError)

    expect(LegacyMigrator.timezone_for_goal(goal)).to be_nil
  end

  it 'returns nil if the timezone is nil' do
    expect(LegacyMigrator.timezone_for_goal(goal)).to be_nil
  end

  it 'returns nil if the timezone is "visitor"' do
    goal.data_json['dates_timezone'] = 'visitor'

    expect(LegacyMigrator.timezone_for_goal(goal)).to be_nil
  end

  it 'returns nil if the timezone is "false"' do
    goal.data_json['dates_timezone'] = 'false'

    expect(LegacyMigrator.timezone_for_goal(goal)).to be_nil
  end

  it 'returns the timezone string without the offset' do
    goal.data_json['dates_timezone'] = '(GMT-06:00) Central Time (US & Canada)'

    expect(LegacyMigrator.timezone_for_goal(goal)).to eq('Central Time (US & Canada)')
  end
end

describe LegacyMigrator, '#bar_is_mobile?' do
  it 'returns true if legacy bar#target_segment equals the mobile code' do
    legacy_bar = double 'legacy_bar', target_segment: 'dv:mobile'

    expect(LegacyMigrator.bar_is_mobile?(legacy_bar)).to be_true
  end

  it 'returns true if legacy bar has a mobile json setting' do
    legacy_bar = double 'legacy_bar', target_segment: nil, settings_json: { 'target' => 'dv:mobile' }

    expect(LegacyMigrator.bar_is_mobile?(legacy_bar)).to be_true
  end

  it 'returns false if both legacy bar#target_segment and no mobile json setting is set' do
    legacy_bar = double 'legacy_bar', target_segment: nil, settings_json: {}

    expect(LegacyMigrator.bar_is_mobile?(legacy_bar)).to be_falsey
  end
end
