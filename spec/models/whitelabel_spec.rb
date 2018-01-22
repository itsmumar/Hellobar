describe Whitelabel do
  it { is_expected.to validate_presence_of :domain }
  it { is_expected.to validate_presence_of :subdomain }

  it { is_expected.to validate_presence_of :status }
  it { is_expected.to validate_inclusion_of(:status).in_array(Whitelabel::STATUSES) }

  it { is_expected.to validate_presence_of :site }

  it { is_expected.to allow_value('hellobar.com').for :domain }
  it { is_expected.to allow_value('abc.cdefg').for :domain }
  it { is_expected.to allow_value('Iñtërnâtiônàlizæt.iøn').for :domain }

  it { is_expected.not_to allow_value('word').for :domain }
  it { is_expected.not_to allow_value('email@me.com').for :domain }
  it { is_expected.not_to allow_value('%!%$#G@').for :domain }
  it { is_expected.not_to allow_value('http://www.cnn.com/').for :domain }
  it { is_expected.not_to allow_value('www.cnn.com/').for :domain }
  it { is_expected.not_to allow_value('www.cnn.com?').for :domain }

  it { is_expected.to allow_value('Iñtërnâtiônàlizætiøn').for :subdomain }
  it { is_expected.to allow_value('email').for :subdomain }
end
