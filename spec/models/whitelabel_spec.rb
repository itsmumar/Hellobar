describe Whitelabel do
  it { is_expected.to validate_presence_of :domain }
  it { is_expected.to validate_presence_of :subdomain }

  it { is_expected.to validate_presence_of :status }
  it { is_expected.to validate_inclusion_of(:status).in_array(Whitelabel::STATUSES) }

  it { is_expected.to validate_presence_of :site }

  context 'domain/subdomain validations' do
    let!(:site) { create :site }

    %w[abc.cdefg Iñtërnâtiônàlizæt.iøn].each do |domain|
      it "allows #{ domain } as domain" do
        subdomain = "email.#{ domain }"
        whitelabel = Whitelabel.new site: site, subdomain: subdomain, domain: domain

        expect(whitelabel).to be_valid
      end
    end

    it 'does not allow domain to be used as subdomain' do
      subdomain = domain = 'hellobar.com'

      whitelabel = Whitelabel.new site: site, subdomain: subdomain, domain: domain

      expect(whitelabel).not_to be_valid
      expect(whitelabel.errors[:subdomain]).to be_present
    end

    it 'does not allow a domain which is not a part of subdomain' do
      domain = 'hellobar.com'
      subdomain = 'email.someone.com'

      whitelabel = Whitelabel.new site: site, subdomain: subdomain, domain: domain

      expect(whitelabel).not_to be_valid
      expect(whitelabel.errors[:domain]).to be_present
    end

    it 'does not allow improper domains' do
      domain = 'hellobar'
      subdomain = 'email.hellobar.com'

      whitelabel = Whitelabel.new site: site, subdomain: subdomain, domain: domain

      expect(whitelabel).not_to be_valid
      expect(whitelabel.errors[:domain]).to be_present
    end

    it 'does not allow urls as domains' do
      domain = 'https://www.hellobar.com'
      subdomain = 'email.hellobar.com'

      whitelabel = Whitelabel.new site: site, subdomain: subdomain, domain: domain

      expect(whitelabel).not_to be_valid
      expect(whitelabel.errors[:domain]).to be_present
    end

    it 'does not allow hosts with paths as domains' do
      domain = 'hellobar.com/faq'
      subdomain = 'email.hellobar.com'

      whitelabel = Whitelabel.new site: site, subdomain: subdomain, domain: domain

      expect(whitelabel).not_to be_valid
      expect(whitelabel.errors[:domain]).to be_present
    end
  end
end
