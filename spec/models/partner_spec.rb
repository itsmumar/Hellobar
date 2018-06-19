describe Partner do
  subject { build(:partner) }

  it { is_expected.to validate_presence_of(:first_name) }
  it { is_expected.to validate_presence_of(:last_name) }
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_presence_of(:website_url) }
  it { is_expected.to validate_presence_of(:affiliate_identifier) }
  it { is_expected.to validate_uniqueness_of(:affiliate_identifier) }
  it { is_expected.to validate_presence_of(:partner_plan) }

  it { is_expected.to allow_value('abc@example.com').for(:email) }
  it { is_expected.not_to allow_value('example').for(:email) }
  it { is_expected.not_to allow_value('@example').for(:email) }

  it { is_expected.to allow_value('http://example.com').for(:website_url) }
  it { is_expected.to allow_value('https://example.com').for(:website_url) }
  it { is_expected.not_to allow_value('example').for(:website_url) }
  it { is_expected.not_to allow_value('example.com').for(:website_url) }
  it { is_expected.not_to allow_value('https://example$$$.com').for(:website_url) }
end
