describe Authentication do
  it { is_expected.to validate_presence_of :user }
  it { is_expected.to validate_presence_of :provider }
end
