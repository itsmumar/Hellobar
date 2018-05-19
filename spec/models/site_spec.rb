describe Site do
  let(:site) { create(:site, :with_user, :with_rule) }
  let(:pro_site) { create(:site, :pro) }

  it_behaves_like 'an object with a valid url'

  it 'is able to access its owner' do
    expect(site.owners.first).not_to be_nil
  end

  it 'allows creating a second site with the same url' do
    url = 'http://test.com'
    user = create :user
    first_site = create :site, user: user, url: url
    second_site = create :site, user: user, url: url

    expect(first_site).to be_valid
    expect(first_site).to be_persisted
    expect(second_site).to be_valid
    expect(second_site).to be_persisted
  end

  it 'allows having membership access to two sites with the same url' do
    url = 'http://test.com'
    membership = create :site_membership

    new_site = membership.user.sites.create url: url

    expect(new_site).to be_valid
    expect(new_site).to be_persisted
  end

  it 'destroys the subscription when site is destroyed' do
    site = create :site, :pro

    site.destroy

    expect(site.subscriptions.with_deleted.last).to be_deleted
  end

  describe '#owners_and_admins' do
    it "should return site's owners & admins" do
      create(:site_membership, :admin, site: site)
      %w[owner admin].each do |role|
        expect(site.owners_and_admins.where(site_memberships: { role: role }).count).to eq(1)
      end
    end
  end

  describe '#create_default_rules' do
    it 'creates rules for the site' do
      expect {
        site.create_default_rules
      }.to change { site.rules.count }.by(3)
    end
  end

  describe '#free?' do
    it 'is true when there is no subscription' do
      expect(site).to be_free
    end

    it 'is true for sites with a free-level subscriptions' do
      expect(site).to be_free
    end

    it 'is true for sites with a free-plus-level subscriptions' do
      site.subscriptions << Subscription::FreePlus.new(schedule: 'monthly')
      expect(site).to be_free
    end

    it 'is false for pro sites' do
      expect(pro_site).not_to be_free
    end

    it 'is false for pro comped sites' do
      site.subscriptions << Subscription::ProComped.new(schedule: 'monthly')
      expect(site).not_to be_free
    end
  end

  describe '#script_installed?' do
    it 'is delegated to #script' do
      expect(site.script).to receive(:installed?)
      site.script_installed?
    end
  end

  describe '#pro_managed?' do
    it 'returns true if the site has a ProManaged subscription' do
      site = create :site
      create :subscription, :pro_managed, site: site

      expect(site).to be_pro_managed
    end

    it 'returns false if the site does not have a ProManaged subscription' do
      site = create :site
      create :subscription, :free, site: site
      create :subscription, :pro, site: site

      expect(site).not_to be_pro_managed
    end
  end

  describe 'url formatting' do
    it 'adds the protocol if not present' do
      site = Site.new(url: 'zombo.com')
      site.valid?
      expect(site.url).to eq('http://zombo.com')
    end

    it 'keeps original protocol' do
      site = Site.new(url: 'https://zombo.com')
      site.valid?
      expect(site.url).to eq('https://zombo.com')

      site = Site.new(url: 'http://zombo.com')
      site.valid?
      expect(site.url).to eq('http://zombo.com')
    end

    it 'removes the path, if provided' do
      urls = %w[
        zombo.com/welcometozombocom
        zombo.com/anythingispossible?at=zombocom
        zombo.com?theonlylimit=yourimagination&at=zombocom#welcome
      ]

      urls.each do |url|
        site = Site.new(url: url)
        site.valid?
        expect(site.url).to eq('http://zombo.com')
      end
    end

    it 'accepts valid inputs' do
      urls = %w[
        zombo.com
        http://zombo.com/
        http://zombo.com/welcome
        http://zombo2.com/welcome
        horelement.bike
      ]

      urls.each do |url|
        site = Site.new(url: url)
        site.valid?
        expect(site.errors[:url]).to be_empty
      end
    end

    it 'is invalid without a properly-formatted url' do
      site = Site.new(url: 'my great website dot com')
      expect(site).not_to be_valid
      expect(site.errors[:url]).not_to be_empty
    end

    it 'is invalid with an email' do
      site = Site.new(url: 'my@website.com')
      expect(site).not_to be_valid
      expect(site.errors[:url]).not_to be_empty
    end

    it 'is invalid without a url' do
      site = Site.new(url: '')
      expect(site).not_to be_valid
      expect(site.errors[:url]).not_to be_empty
    end

    it "doesn't try to format a blank URL" do
      site = Site.new(url: '')
      expect(site).not_to be_valid
      expect(site.url).to be_blank
    end
  end

  describe '#set_branding_on_site_elements' do
    let!(:site) { create(:site, :with_rule) }
    let!(:element) { create(:site_element, :traffic, rule: site.rules.first!, show_branding: true) }

    context 'when subscription is pro' do
      let!(:subscription) { create(:subscription, :pro, :paid, site: site) }

      it 'does not show branding' do
        site.send(:set_branding_on_site_elements)
        expect(element.reload.show_branding).to be_falsey
      end
    end

    context 'when subscription is free' do
      let!(:subscription) { create(:subscription, :free, site: site) }

      it 'shows branding' do
        site.send(:set_branding_on_site_elements)
        expect(element.reload.show_branding).to be_truthy
      end
    end
  end

  describe '#script_url' do
    it 'is delegated to #script' do
      expect(site.script).to receive(:url)
      site.script_url
    end
  end

  describe '.host' do
    def host(url)
      Site.new(url: url).host
    end

    it 'removes www' do
      expect(host('http://www.cnn.com')).to eq('www.cnn.com')
    end

    it 'does not remove www from other parts of the url' do
      expect(host('cnnwww.com/')).to eq('cnnwww.com')
    end

    it 'does not removes the www1 subdomain' do
      expect(host('www1.abc.com/')).to eq('www1.abc.com')
    end

    it 'returns nil if invalid' do
      expect(host('http://')).to be_nil
    end

    it 'does not encodes non-unicode characters' do
      expect(host('яндекс.рф')).to eq('яндекс.рф')
    end
  end

  describe '#had_wordpress_bars?' do
    it 'returns true when some site elements are migrated from wordpress' do
      site_element = create(:site_element, wordpress_bar_id: 123)
      expect(site_element.site.had_wordpress_bars?).to be(true)
    end

    it 'returns false when no site elements are migrated from wordpress' do
      site_element = create(:site_element, wordpress_bar_id: nil)
      expect(site_element.site.had_wordpress_bars?).to be(false)
    end
  end

  describe 'bills_with_payment_issues' do
    let(:user) { create :user }
    let(:site) { create :site, user: user }
    let(:credit_card) { create :credit_card, user: user }
    let(:last_bill) { site.bills.last }

    def change_subscription(subscription, schedule = 'monthly')
      ChangeSubscription.new(
        site,
        { subscription: subscription, schedule: schedule },
        credit_card
      ).call
    end

    before { stub_cyber_source :purchase }

    it 'returns bills that are problem' do
      expect(site.bills_with_payment_issues).to be_empty
      change_subscription('pro')
      last_bill.fail!
      expect(site.bills_with_payment_issues).to match_array [last_bill]
    end
  end

  describe '#membership_for_user' do
    let(:user) { site.owners.last }

    it 'returns membership' do
      expect(site.membership_for_user(user)).to eql user.site_memberships.first
    end
  end

  describe '#statistics' do
    let(:statistics) { double('statistics') }

    it 'calls FetchSiteStatistics' do
      expect(FetchSiteStatistics)
        .to receive_service_call
        .with(site, days_limit: 7)
        .and_return(statistics)
      expect(site.statistics).to be statistics
    end
  end

  describe '#communication_types' do
    it 'returns array of strings' do
      site.communication_types = Site::COMMUNICATION_TYPES.map(&:to_s)
      expect(site.communication_types).to eql Site::COMMUNICATION_TYPES.map(&:to_s)

      expect(site[:communication_types]).to eql Site::COMMUNICATION_TYPES.join(',')
    end
  end

  describe '#gdpr_enabled?' do
    before do
      site.communication_types = [Site::COMMUNICATION_TYPES.first]
      site.privacy_policy_url = 'google.com'
      site.terms_and_conditions_url = 'google.com'
    end

    context 'when all gdpr-related attributes are present' do
      specify { expect(site.gdpr_enabled?).to be_truthy }
    end

    context 'when privacy_policy_url is blank' do
      before { site.privacy_policy_url = nil }
      specify { expect(site.gdpr_enabled?).to be_falsey }
    end

    context 'when terms_and_conditions_url is blank' do
      before { site.terms_and_conditions_url = nil }
      specify { expect(site.gdpr_enabled?).to be_falsey }
    end

    context 'when communication_types is blank' do
      before { site.communication_types = [] }
      specify { expect(site.gdpr_enabled?).to be_falsey }
    end
  end
end
