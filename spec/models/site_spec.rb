require 'spec_helper'

describe Site do
  fixtures :all

  before(:each) do
    @site = sites(:zombo)
  end

  it_behaves_like 'an object with a valid url'

  it 'is able to access its owner' do
    expect(@site.owners.first).to eq(users(:joey))
  end

  describe '#owners_and_admins' do
    it "should return site's owners & admins" do
      create(:site_membership, :admin, :site => @site)
      %w(owner admin).each do |role|
        expect(@site.owners_and_admins.where(site_memberships: { role: role }).count).to eq(1)
      end
    end
  end

  describe '#create_default_rules' do
    it 'creates rules for the site' do
      site = sites(:horsebike)

      expect {
        site.create_default_rules
      }.to change { site.rules.count }.by(3)
    end
  end

  describe '#is_free?' do
    it 'is true initially' do
      site = Site.new
      expect(site.is_free?).to be_true
    end

    it 'is true for sites with a free-level subscriptions' do
      expect(sites(:horsebike).is_free?).to be_true
    end

    it 'is true for sites with a free-plus-level subscriptions' do
      site = sites(:horsebike)
      site.change_subscription(Subscription::FreePlus.new(schedule: 'monthly'))
      expect(site.is_free?).to be_true
    end

    it 'is false for pro sites' do
      expect(sites(:pro_site).is_free?).to be_false
    end

    it 'is false for pro comped sites' do
      site = sites(:horsebike)
      site.change_subscription(Subscription::ProComped.new(schedule: 'monthly'))
      expect(site.is_free?).to be_false
    end
  end

  describe '#change_subscription' do
    it 'runs set_branding_on_site_elements after changing subscription' do
      site = sites(:horsebike)
      expect(site).to receive(:set_branding_on_site_elements)
      site.change_subscription(Subscription::ProComped.new(schedule: 'monthly'))
    end

    it 'regenerates the script' do
      site = sites(:horsebike)
      site.update_attribute(:script_generated_at, 1.day.ago)
      site.change_subscription(Subscription::ProComped.new(schedule: 'monthly'))
      expect(site.needs_script_regeneration?).to be(true)
    end

    it 'applies the discount when changing subscription to pro and it belongs to a discount tier' do
      user = create(:user)
      bills = []

      zero_discount_subs = Subscription::Pro.defaults[:discounts].detect { |x| x.tier == 0 }.slots
      zero_discount_subs.times do
        bill = create(:pro_bill, status: :paid)
        bill.site.users << user
        user.reload
        bill.subscription.payment_method.update(user: user)
        bill.update(discount: bill.calculate_discount)
      end

      site = user.sites.create(url: random_uniq_url)
      site.change_subscription(Subscription::Pro.new(schedule: 'monthly'), user.payment_methods.first)
      expect(site.bills.paid.first.discount > 0).to be(true)
    end
  end

  describe '#highest_tier_active_subscription' do
    before do
      @payment_method = create(:payment_method)
      ownership = create(:site_ownership, user: @payment_method.user)
      @site = ownership.site
    end

    it 'returns nil when there are no active subscriptions' do
      expect(@site.highest_tier_active_subscription).to be(nil)
    end

    it 'returns the highest tier active subscription' do
      @site.change_subscription(Subscription::Free.new(schedule: 'monthly', user: @payment_method.user), @payment_method)
      @site.change_subscription(Subscription::Pro.new(schedule: 'monthly', user: @payment_method.user), @payment_method)
      expect(@site.highest_tier_active_subscription).to be_a(Subscription::Pro)
    end

    it 'returns only active subscriptions' do
      @site.change_subscription(Subscription::Free.new(schedule: 'yearly'), @payment_method)
      @site.change_subscription(Subscription::Pro.new(schedule: 'monthly'), @payment_method)
      travel_to 2.month.from_now do
        expect(@site.highest_tier_active_subscription).to be_a(Subscription::Free)
      end
    end
  end

  describe '#has_pro_managed_subscription?' do
    it 'returns true if the site has a ProManaged subscription' do
      site = build_stubbed :site
      subscription = build_stubbed :subscription, :pro_managed

      expect(site).to receive(:subscriptions).and_return [subscription]

      expect(site).to have_pro_managed_subscription
    end

    it 'returns false if the site does not have a ProManaged subscription' do
      site = build_stubbed :site
      free = build_stubbed :subscription, :free
      pro = build_stubbed :subscription, :pro

      expect(site).to receive(:subscriptions).and_return [free, pro]

      expect(site).not_to have_pro_managed_subscription
    end
  end

  describe 'url formatting' do
    it 'adds the protocol if not present' do
      site = Site.new(:url => 'zombo.com')
      site.valid?
      expect(site.url).to eq('http://zombo.com')
    end

    it 'keeps original protocol' do
      site = Site.new(:url => 'https://zombo.com')
      site.valid?
      expect(site.url).to eq('https://zombo.com')

      site = Site.new(:url => 'http://zombo.com')
      site.valid?
      expect(site.url).to eq('http://zombo.com')
    end

    it 'removes the path, if provided' do
      urls = %w(
        zombo.com/welcometozombocom
        zombo.com/anythingispossible?at=zombocom
        zombo.com?theonlylimit=yourimagination&at=zombocom#welcome
      )

      urls.each do |url|
        site = Site.new(:url => url)
        site.valid?
        expect(site.url).to eq('http://zombo.com')
      end
    end

    it 'accepts valid inputs' do
      urls = %w(
        zombo.com
        http://zombo.com/
        http://zombo.com/welcome
        http://zombo2.com/welcome
        horse.bike
      )

      urls.each do |url|
        site = Site.new(:url => url)
        site.valid?
        expect(site.errors[:url]).to be_empty
      end
    end

    it 'is invalid without a properly-formatted url' do
      site = Site.new(:url => 'my great website dot com')
      expect(site).not_to be_valid
      expect(site.errors[:url]).not_to be_empty
    end

    it 'is invalid with an email' do
      site = Site.new(:url => 'my@website.com')
      expect(site).not_to be_valid
      expect(site.errors[:url]).not_to be_empty
    end

    it 'is invalid without a url' do
      site = Site.new(:url => '')
      expect(site).not_to be_valid
      expect(site.errors[:url]).not_to be_empty
    end

    it "doesn't try to format a blank URL" do
      site = Site.new(:url => '')
      expect(site).not_to be_valid
      expect(site.url).to be_blank
    end
  end

  describe '#script_content' do
    it 'generates the contents of the script for a site' do
      Hello::DataAPI.stub(:lifetime_totals => nil)
      script = @site.script_content(false)

      expect(script).to match(/HB_SITE_ID/)
      expect(script).to include(@site.site_elements.first.id.to_s)
    end

    it 'generates the compressed contents of the script for a site' do
      Hello::DataAPI.stub(:lifetime_totals => nil)
      script = @site.script_content

      expect(script).to match(/HB_SITE_ID/)
      expect(script).to include(@site.site_elements.first.id.to_s)
    end
  end

  describe 'url_uniqueness' do
    let(:membership) { create(:site_membership) }

    it 'returns false if the url is not unique to the user' do
      s2 = membership.user.sites.create(url: 'different.com')
      s2.url = membership.site.url

      expect(s2.valid?).to be_false
    end

    it 'returns true if the url is unqiue to the user' do
      s2 = membership.user.sites.create(url: 'uniqueurl.com')

      expect(s2.valid?).to be_true
    end
  end

  describe '#generate_script' do
    it 'delegates :generate_static_assets to delay' do
      expect(@site).to receive(:delay).with(:generate_static_assets, anything)
      @site.generate_script
    end

    it 'calls generate_static_assets if immediately option is specified' do
      expect(@site).to receive(:generate_static_assets)
      @site.generate_script(immediately: true)
    end
  end

  describe '#generate_static_assets' do
    before do
      @mock_storage = double('asset_storage')
      allow(Hello::AssetStorage).to receive(:new).and_return(@mock_storage)
    end

    it 'generates and uploads the script content for a site' do
      ScriptGenerator.any_instance.stub(:pro_secret => 'asdf')
      Hello::DataAPI.stub(:lifetime_totals => nil)
      script_content = @site.script_content(true)
      script_name = @site.script_name

      mock_storage = double('asset_storage')
      expect(mock_storage).to receive(:create_or_update_file_with_contents).with(script_name, script_content)
      Hello::AssetStorage.stub(:new => mock_storage)

      @site.generate_script
    end

    it 'generates scripts for each wordpress bar' do
      site_element = create(:site_element, wordpress_bar_id: 123)
      user = create(:user, wordpress_user_id: 456)
      site_element.site.users << user

      allow_any_instance_of(ScriptGenerator).to receive(:pro_secret).and_return('asdf')
      allow(Hello::DataAPI).to receive(:lifetime_totals).and_return(nil)
      site = site_element.site.reload

      # First, generate for site, then for the site element
      expect(@mock_storage).to receive(:create_or_update_file_with_contents).with(anything, anything).ordered
      expect(@mock_storage).to receive(:create_or_update_file_with_contents).with("#{user.wordpress_user_id}_#{site_element.wordpress_bar_id}.js", anything).ordered
      site.send(:generate_static_assets)
    end
  end

  it 'blanks-out the site script when destroyed' do
    mock_storage = double('asset_storage')
    expect(mock_storage).to receive(:create_or_update_file_with_contents).with(@site.script_name, '')
    Hello::AssetStorage.stub(:new => mock_storage)

    @site.destroy
  end

  it 'should soft-delete' do
    allow(@site).to receive(:generate_static_assets)
    @site.destroy
    expect(Site.only_deleted).to include(@site)
  end

  describe '#has_script_installed?' do
    context 'when installed' do
      it 'updates the script_installed_at' do
        allow(@site).to receive(:script_installed_db?) { false }
        allow(@site).to receive(:script_installed_api?) { true }

        expect {
          @site.has_script_installed?
        }.to change(@site, :script_installed_at)
      end

      it 'redeems referrals' do
        allow(@site).to receive(:script_installed_db?) { false }
        allow(@site).to receive(:script_installed_api?) { true }

        expect(Referrals::RedeemForRecipient).to receive(:run).with(site: @site)

        @site.has_script_installed?
      end

      it 'tracks the install event' do
        allow(@site).to receive(:script_installed_db?) { false }
        allow(@site).to receive(:script_installed_api?) { true }

        expect(Analytics).to receive(:track).with(:site, @site.id, 'Installed')

        @site.has_script_installed?
      end
    end

    context 'when uninstalled' do
      it 'updates the script_uninstalled_at' do
        allow(@site).to receive(:script_installed_db?) { true }
        allow(@site).to receive(:script_installed_api?) { false }

        expect {
          @site.has_script_installed?
        }.to change(@site, :script_uninstalled_at)
      end

      it 'tracks the uninstall event' do
        allow(@site).to receive(:script_installed_db?) { true }
        allow(@site).to receive(:script_installed_api?) { false }

        expect(Analytics).to receive(:track).with(:site, @site.id, 'Uninstalled')

        @site.has_script_installed?
      end
    end
  end

  describe '#script_installed_api?' do
    it 'is true if there is only one day of data' do
      expect(Hello::DataAPI).to receive(:lifetime_totals).and_return({ '1' => [[1, 0]] })
      expect(@site.script_installed_api?).to be_true
    end

    it 'is true if there are multiple days of data' do
      expect(Hello::DataAPI).to receive(:lifetime_totals).and_return({ '1' => [[1, 0], [2, 0]] })
      expect(@site.script_installed_api?).to be_true
    end

    it 'is false if the api returns nil' do
      expect(Hello::DataAPI).to receive(:lifetime_totals).and_return(nil)
      expect(@site.script_installed_api?).to be_false
    end

    it 'is false if the api returns an empty hash' do
      expect(Hello::DataAPI).to receive(:lifetime_totals).and_return({})
      expect(@site.script_installed_api?).to be_false
    end

    it 'is true if one element has views but others do not' do
      expect(Hello::DataAPI).to receive(:lifetime_totals).and_return({
        '1' => [[1, 0], [1, 0], [1, 0], [1, 0], [1, 0], [1, 0], [1, 0], [1, 0]],
        '2' => [[1, 0], [1, 0], [2, 0], [2, 0], [2, 0], [2, 0], [2, 0], [2, 0]]
      })

      expect(@site.script_installed_api?).to be_true
    end

    it 'is true if any of the elements have been installed in the last 7 days' do
      expect(Hello::DataAPI).to receive(:lifetime_totals).and_return({
        '1' => [[1, 0], [1, 0], [1, 0], [1, 0], [1, 0], [1, 0], [1, 0], [1, 0]],
        '2' => [[1, 0], [1, 0]]
      })

      expect(@site.script_installed_api?).to be_true
    end

    it 'is false if there have been no views in the last 10 days' do
      expect(Hello::DataAPI).to receive(:lifetime_totals).and_return({
        '1' => [[1, 0], [1, 0], [1, 0], [1, 0], [1, 0], [1, 0], [1, 0], [1, 0], [1, 0], [1, 0], [1, 0]],
        '2' => [[0, 0]]
      })

      expect(@site.script_installed_api?).to be_false
    end
  end

  describe '#script_installed_db?' do
    before do
      @site.script_installed_at = nil
      @site.script_uninstalled_at = nil
    end

    it 'is true if installed_at is set' do
      @site.script_installed_at = 1.week.ago
      expect(@site.script_installed_db?).to be_true
    end

    it 'is true if installed_at is more recent than uninstalled_at' do
      @site.script_installed_at = 1.day.ago
      @site.script_uninstalled_at = 1.week.ago

      expect(@site.script_installed_db?).to be_true
    end

    it 'is false if uninstalled_at is more recent than installed_at' do
      @site.script_installed_at = 1.week.ago
      @site.script_uninstalled_at = 1.day.ago

      expect(@site.script_installed_db?).to be_false
    end
  end

  describe 'calculate_bill' do
    context 'trial_period is specified' do
      it 'should set the bill amount to 0' do
        sub = subscriptions(:zombo_subscription)
        bill = sub.site.send(:calculate_bill, sub, true, 20.day)
        expect(bill.amount).to eq(0)
      end

      it 'should set the end_at of the bill to the current time + the trial period' do
        sub = subscriptions(:zombo_subscription)
        travel_to Time.now do
          bill = sub.site.send(:calculate_bill, sub, true, 20.day)
          expect(bill.end_date).to eq(Time.now + 20.day)
        end
      end
    end

    context 'trial_period is not specified' do
      it 'should set the bill amount to subscription.amount' do
        sub = subscriptions(:zombo_subscription)
        bill = sub.site.send(:calculate_bill, sub, true)
        expect(bill.amount).to eq(sub.amount)
      end

      it 'should set the bill end_date to ' do
        sub = subscriptions(:zombo_subscription)
        travel_to Time.current do
          bill = sub.site.send(:calculate_bill, sub, true)
          expect(bill.end_date).to eq(Bill::Recurring.next_month(Time.current) - 1.hour)
        end
      end
    end
  end

  describe '#url_exists?' do
    it 'should return false if no other site exists with the url' do
      expect(Site.create(url: 'http://abc.com').url_exists?).to be_false
    end

    it 'should return true if another site exists with the url' do
      Site.create(url: 'http://abc.com')
      expect(Site.new(url: 'http://abc.com').url_exists?).to be_true
    end

    it 'should return true if another site exists even with other protocol' do
      Site.create(url: 'http://abc.com')
      expect(Site.new(url: 'https://abc.com').url_exists?).to be_true
    end

    it 'should scope to user if user is given' do
      u1 = users(:joey)
      u1.sites.create(url: 'http://abc.com')
      u2 = users(:wootie)
      expect(u2.sites.build(url: 'http://abc.com').url_exists?(u2)).to be_false
    end

    it 'should ignore protocol if user scoped call' do
      u1 = users(:joey)
      u1.sites.create(url: 'http://abc.com')
      u2 = users(:wootie)
      expect(u2.sites.build(url: 'https://abc.com').url_exists?(u2)).to be_false
    end
  end

  describe '#set_branding_on_site_elements' do
    let(:subscription) { raise('subscription must be overridden') }

    let(:site) { subscription.site }
    let(:se) { site_elements(:zombo_traffic) }

    before do
      se.rule = site.rules.first
      se.show_branding = true
      se.save
      site.send(:set_branding_on_site_elements)
      se.reload
    end

    context 'when subscription is pro' do
      let(:subscription) { subscriptions(:pro_subscription) }

      it 'does not show branding' do
        expect(se.show_branding).to be_false
      end
    end

    context 'when subscription is free' do
      let(:subscription) { subscriptions(:free_subscription) }

      it 'shows branding' do
        expect(se.show_branding).to be_true
      end
    end
  end

  describe '#find_by_script' do
    it 'should return the site if the script name matches' do
      site = create(:site)
      expect(Site.find_by_script(site.script_name)).to eq(site)
    end

    it 'should return nil if no site exists with that script' do
      allow(Site).to receive(:maximum).and_return(10) # so that it doesn't run forever
      expect(Site.find_by_script('foo')).to be_nil
    end
  end

  describe '.normalize_url' do
    it 'should remove www' do
      expect(Site.normalize_url('http://www.cnn.com').host).to eq('www.cnn.com')
    end

    it 'should not remove www from other parts of the url' do
      expect(Site.normalize_url('cnnwww.com/').host).to eq('cnnwww.com')
    end

    it 'should not remove the www1 subdomain' do
      expect(Site.normalize_url('www1.abc.com/').host).to eq('www1.abc.com')
    end

    it 'should normalize to http' do
      expect(Site.normalize_url('https://cnn.com').scheme).to eq('https')
    end
  end

  describe '#normalized_url' do
    it 'returns shorter URLs for different sites' do
      site = Site.new(url: 'http://asdf.com')
      expect(site.normalized_url).to eq('asdf.com')

      site = Site.new(url: 'http://www.asdf.com')
      expect(site.normalized_url).to eq('www.asdf.com')

      site = Site.new(url: 'http://cs.horse.bike')
      expect(site.normalized_url).to eq('cs.horse.bike')
    end

    it 'returns the site URL if normalized_url returns nil' do
      site = Site.new(url: 'https://ca-staging-uk')

      expect(site.normalized_url).to eql('ca-staging-uk')
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

  describe '#script_installed_on_homepage?' do
    it 'returns true when the script is installed at the url'  do
      site_element = create(:site_element)
      site = site_element.site
      allow(HTTParty).to receive(:get).and_return("<html><script src='#{site_element.site.script_url}'></html>")
      expect(site.script_installed_on_homepage?).to be(true)
    end

    it 'returns true when the site had wordpress bars and has the old script'  do
      site_element = create(:site_element, wordpress_bar_id: 123)
      site = site_element.site
      allow(HTTParty).to receive(:get).and_return("<html><script src='hellobar.js'></html>")
      expect(site.script_installed_on_homepage?).to be(true)
    end

    it 'returns false when the site does not have the script'  do
      site_element = create(:site_element)
      site = site_element.site
      allow(HTTParty).to receive(:get).and_return("<html><script src='foobar.js'></html>")
      expect(site.script_installed_on_homepage?).to be(false)
    end
  end

  describe 'after_touch' do
    context 'not destroyed' do
      it 'sets needs_script_regeneration? to true' do
        site = create(:site)
        site.touch
        expect(site.needs_script_regeneration?).to be(true)
      end
    end

    context 'destroyed' do
      it 'sets needs_script_regeneration? to false' do
        site = create(:site)
        allow(site).to receive(:generate_blank_static_assets)
        site.destroy
        site.touch
        expect(site.needs_script_regeneration?).to be(false)
      end
    end
  end
end
