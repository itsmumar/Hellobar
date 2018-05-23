describe Partner do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_presence_of(:url) }

  it { is_expected.to allow_value('abc@example.com').for(:email) }
  it { is_expected.not_to allow_value('example').for(:email) }
  it { is_expected.not_to allow_value('@example').for(:email) }

  it { is_expected.to allow_value('http://example.com').for(:url) }
  it { is_expected.to allow_value('https://example.com').for(:url) }
  it { is_expected.not_to allow_value('example').for(:url) }
  it { is_expected.not_to allow_value('example.com').for(:url) }
  it { is_expected.not_to allow_value('https://example$$$.com').for(:url) }
end
