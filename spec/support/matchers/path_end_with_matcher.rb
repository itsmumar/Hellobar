RSpec::Matchers.define :path_end_with do |expected|
  match do |actual|
    expect(actual).to be_a(Pathname)
    expect(actual.to_s).to end_with(expected)
  end
end
