describe Whitelabel do
  it { is_expected.to validate_presence_of :domain }

  it { is_expected.to allow_value('abc.cdefg').for :domain }
  it { is_expected.to allow_value('email.hellobar.com').for :domain }
  it { is_expected.to allow_value('Iñtërnâtiônàlizæti.øn').for :domain }
  it { is_expected.not_to allow_value('word').for :domain }
  it { is_expected.not_to allow_value('email@me.com').for :domain }
  it { is_expected.not_to allow_value('%!%$#G@').for :domain }
  it { is_expected.not_to allow_value('http://www.cnn.com/').for :domain }
  it { is_expected.not_to allow_value('www.cnn.com/').for :domain }
  it { is_expected.not_to allow_value('www.cnn.com?').for :domain }

  it { is_expected.to validate_presence_of :status }
  it { is_expected.to validate_inclusion_of(:status).in_array(Whitelabel::STATUSES) }

  it { is_expected.to validate_presence_of :site }
end
