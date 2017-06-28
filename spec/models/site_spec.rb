describe Site do
  let(:site) { create(:site, :with_user, :with_rule) }
  let(:pro_site) { create(:site, :pro) }

  it_behaves_like 'an object with a valid url'

  it 'is able to access its owner' do
    expect(site.owners.first).not_to be_nil
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

  describe '#highest_tier_active_subscription' do
    let(:payment_method) { create(:payment_method) }
    let(:ownership) { create(:site_membership, user: payment_method.user) }
    let(:site) { ownership.site }

    before { stub_cyber_source :purchase, :refund }

    def change_subscription(subscription, schedule = 'monthly')
      ChangeSubscription.new(site, { subscription: subscription, schedule: schedule }, payment_method).call
    end

    it 'returns nil when there are no active subscriptions' do
      expect(site.highest_tier_active_subscription).to be(nil)
    end

    it 'returns the highest tier active subscription among Free and Pro' do
      change_subscription('free')
      change_subscription('pro')

      expect(site.highest_tier_active_subscription).to be_a(Subscription::Pro)
    end

    it 'returns the highest tier active subscription among Pro and Enterprise' do
      change_subscription('pro')
      change_subscription('enterprise')

      expect(site.highest_tier_active_subscription).to be_a(Subscription::Enterprise)
    end

    it 'returns the highest tier active subscription among Pro and ProManaged' do
      change_subscription('free')
      change_subscription('pro')
      site.subscriptions.last.update type: Subscription::ProManaged

      expect(site.highest_tier_active_subscription).to be_a(Subscription::ProManaged)
    end

    it 'returns only active subscriptions' do
      change_subscription('free', 'yearly')
      change_subscription('pro')

      travel_to 2.months.from_now do
        expect(site.highest_tier_active_subscription).to be_a(Subscription::Free)
      end
    end

    context 'when Pro subscription has a refund' do
      it 'returns Free subscription', :freeze do
        change_subscription('free')
        bill = change_subscription('pro')
        RefundBill.new(bill).call

        expect(site.highest_tier_active_subscription).to be_a(Subscription::Free)
      end
    end
  end

  describe '#pro_managed_subscription?' do
    it 'returns true if the site has a ProManaged subscription' do
      site = build_stubbed :site
      subscription = build_stubbed :subscription, :pro_managed

      expect(site).to receive(:subscriptions).and_return [subscription]

      expect(site).to be_pro_managed_subscription
    end

    it 'returns false if the site does not have a ProManaged subscription' do
      site = build_stubbed :site
      free = build_stubbed :subscription, :free
      pro = build_stubbed :subscription, :pro

      expect(site).to receive(:subscriptions).and_return [free, pro]

      expect(site).not_to be_pro_managed_subscription
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

  describe 'url_uniqueness' do
    let(:membership) { create(:site_membership) }

    it 'returns false if the url is not unique to the user' do
      s2 = membership.user.sites.create(url: 'different.com')
      s2.url = membership.site.url

      expect(s2.valid?).to be_falsey
    end

    it 'returns true if the url is unqiue to the user' do
      s2 = membership.user.sites.create(url: 'uniqueurl.com')

      expect(s2.valid?).to be_truthy
    end
  end

  describe '#generate_script' do
    it 'enqueues GenerateStaticScriptJob' do
      expect { site.generate_script }.to have_enqueued_job GenerateStaticScriptJob
    end
  end

  describe '#destroy' do
    let(:mock_upload_to_s3) { double(:upload_to_s3) }

    before do
      allow(Settings).to receive(:store_site_scripts_locally).and_return false
      allow(UploadToS3).to receive(:new).and_return(mock_upload_to_s3)
      allow(mock_upload_to_s3).to receive(:call).with(no_args)
    end

    it 'blanks-out the site script when destroyed' do
      site.destroy
      expect(UploadToS3).to have_received(:new).with(site.script_name, '')
    end

    it 'soft-deletes record' do
      site.destroy
      expect(Site.only_deleted).to include(site)
    end
  end

  describe '#url_exists?' do
    it 'should return false if no other site exists with the url' do
      expect(Site.create(url: 'http://abc.com').url_exists?).to be_falsey
    end

    it 'should return true if another site exists with the url' do
      Site.create(url: 'http://abc.com')
      expect(Site.new(url: 'http://abc.com').url_exists?).to be_truthy
    end

    it 'should return true if another site exists even with other protocol' do
      Site.create(url: 'http://abc.com')
      expect(Site.new(url: 'https://abc.com').url_exists?).to be_truthy
    end

    it 'should scope to user if user is given' do
      u1 = create(:user, :with_site)
      u1.sites.create(url: 'http://abc.com')
      u2 = create(:user, :with_site)
      expect(u2.sites.build(url: 'http://abc.com').url_exists?(u2)).to be_falsey
    end

    it 'should ignore protocol if user scoped call' do
      u1 = create(:user, :with_site)
      u1.sites.create(url: 'http://abc.com')
      u2 = create(:user, :with_site)
      expect(u2.sites.build(url: 'https://abc.com').url_exists?(u2)).to be_falsey
    end
  end

  describe '#set_branding_on_site_elements' do
    let!(:site) { create(:site, :with_rule) }
    let!(:element) { create(:site_element, :traffic, rule: site.rules.first!, show_branding: true) }

    context 'when subscription is pro' do
      let!(:subscription) { create(:subscription, :pro, site: site) }

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

      site = Site.new(url: 'http://cs.horelement.bike')
      expect(site.normalized_url).to eq('cs.horelement.bike')
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

  describe '#update_content_upgrade_styles!' do
    let(:site) { create :site }
    let(:content_upgrade_styles) { generate :content_upgrade_styles }

    it 'updates settings' do
      expect { site.update_content_upgrade_styles! content_upgrade_styles }
        .to change(site, :settings).to('content_upgrade' => content_upgrade_styles)
    end
  end

  describe 'after_commit callback' do
    let(:site) { create :site }
    let(:commit) { site.run_callbacks :commit }

    context 'when skip_script_generation' do
      before { site.skip_script_generation = true }

      it 'does not generate script' do
        expect { commit }.not_to have_enqueued_job GenerateStaticScriptJob
      end
    end

    context 'when not skip_script_generation' do
      before { site.skip_script_generation = false }
      before { site.touch }

      it 'generates script' do
        expect { commit }.to have_enqueued_job GenerateStaticScriptJob
      end
    end

    it 'does not generate test site when not in development mode' do
      expect(HbTestSite).not_to receive :generate_default

      site.touch
      commit
    end

    it 'regenerates test site when in development mode' do
      expect(Rails.env).to receive(:development?).and_return true
      expect(HbTestSite).to receive(:generate_default).with site.id

      site.touch
      commit
    end
  end

  describe 'bills_with_payment_issues' do
    let(:user) { create :user }
    let(:site) { create :site, user: user }
    let(:payment_method) { create :payment_method, user: user }

    def change_subscription(subscription, schedule = 'monthly')
      ChangeSubscription.new(site, { subscription: subscription, schedule: schedule }, payment_method).call
    end

    before { stub_cyber_source :purchase, success: false }

    it 'returns bills that are due' do
      expect(site.bills_with_payment_issues).to be_empty
      bill = change_subscription('pro')
      expect(site.bills_with_payment_issues(true)).to match_array [bill]
    end

    it 'does not return bills not due' do
      bill = change_subscription('pro')
      bill.update! bill_at: 7.days.from_now

      expect(site.bills_with_payment_issues).to be_empty
    end

    it 'does not return bills that we haven\'t attempted to charge at least once' do
      expect(site.bills_with_payment_issues).to be_empty
      bill = change_subscription('pro')
      expect(bill).to be_pending
      bill.billing_attempts.delete_all
      expect(site.bills_with_payment_issues(true)).to be_empty
    end
  end
end
