describe AffiliateInformation do
  it { is_expected.to validate_presence_of :visitor_identifier }
  it { is_expected.to validate_presence_of :affiliate_identifier }
end
