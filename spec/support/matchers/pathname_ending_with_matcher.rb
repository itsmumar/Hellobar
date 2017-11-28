RSpec::Matchers.define :pathname_ending_with do |expected|
  match do |actual|
    expect(actual).to be_a(Pathname)
    expect(actual.to_s).to end_with(expected)
  end
end

RSpec::Matchers.alias_matcher :be_a_pathname_ending_with, :pathname_ending_with
