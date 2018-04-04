describe AnalyticsProvider do
  let!(:user) { create :user }
  let!(:site) { create :site, user: user }

  let(:adapter) { double('adapter') }
  let(:provider) { AnalyticsProvider.new(adapter) }

  def track(*args)
    provider.fire_event(*args)
  end

  describe '#signed_up' do
    it 'tracks "signed-up"' do
      expect(adapter)
        .to receive(:track)
        .with(event: 'signed-up', user: user, params: {})

      track('signed-up', user: user)
    end
  end

  describe '#invited_member' do
    let(:event) { 'invited-member' }

    it 'tracks "invited-member"' do
      expect(adapter)
        .to receive(:track)
        .with(event: event, user: user, params: { site_url: site.url })

      track(event, user: user, site: site)
    end
  end

  describe '#created_site' do
    let(:event) { 'created-site' }

    it 'tracks "created-site"' do
      expect(adapter)
        .to receive(:track)
        .with(event: event, user: user, params: { url: site.url })

      track(event, user: user, site: site)
    end
  end

  describe '#installed_script' do
    let(:event) { 'installed-script' }

    it 'tracks "installed-script"' do
      expect(adapter)
        .to receive(:track)
        .with(event: event, user: user, params: { url: site.url })

      track(event, user: user, site: site)
    end
  end

  describe '#uninstalled_script' do
    let(:event) { 'uninstalled-script' }

    it 'tracks "uninstalled-script"' do
      expect(adapter)
        .to receive(:track)
        .with(event: event, user: user, params: { url: site.url })

      track(event, user: user, site: site)
    end
  end

  describe '#created_contact_list' do
    let(:event) { 'created-contact-list' }
    let(:contact_list) { create :contact_list, :mailchimp }

    it 'tracks "created-contact-list"' do
      expect(adapter)
        .to receive(:track)
        .with(event: event, user: user, params: {
          identity: 'mailchimp',
          site_url: contact_list.site.url
        })

      track(event, user: user, contact_list: contact_list)
    end
  end

  describe '#created_bar' do
    let(:event) { 'created-bar' }
    let(:site_element) { create :site_element }

    it 'tracks "created-bar"' do
      expect(adapter)
        .to receive(:track)
        .with(event: event, user: user, params: {
          bar_type: site_element.type,
          goal: site_element.element_subtype,
          site_url: site_element.site.url
        })

      track(event,
        user: user,
        site_element: site_element)
    end
  end

  describe '#changed_subscription' do
    let(:event) { 'changed-subscription' }
    let(:site) { create :site, :pro }
    let(:subscription) { site.current_subscription }

    before { allow(adapter).to receive(:tag_users) }

    it 'tracks "changed-subscription"' do
      expect(adapter)
        .to receive(:track)
        .with(event: event, user: user, params: {
          amount: subscription.amount,
          subscription: subscription.name,
          schedule: subscription.schedule,
          site_url: site.url,
          trial_days: 0
        })

      track(event, user: user, subscription: subscription)
    end

    it 'tags users with "Paid" and "Subscription.name" tags' do
      expect(adapter)
        .to receive(:tag_users)
        .with('Paid', anything)

      expect(adapter)
        .to receive(:tag_users)
        .with('Pro', anything)

      expect(adapter).to receive(:track)

      track(event, user: user, subscription: subscription)
    end
  end

  describe '#used_promo_code' do
    let(:event) { 'used-promo-code' }
    let(:site) { create :site }
    let(:coupon) { create :coupon }

    it 'tracks "created-bar"' do
      expect(adapter)
        .to receive(:track)
        .with(event: event, user: user, params: {
          code: coupon.label,
          trial_days: coupon.trial_period,
          site_url: site.url
        })

      track(event, user: user, site: site, coupon: coupon)
    end
  end
end
