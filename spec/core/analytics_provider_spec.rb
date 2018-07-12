describe AnalyticsProvider do
  let!(:user) { create :user }
  let!(:site) { create :site, user: user }

  let(:adapter) { double('adapter') }
  let(:provider) { AnalyticsProvider.new(adapter) }

  def track(*args)
    provider.fire_event(*args)
  end

  describe '#signed_up' do
    context 'when regular signup' do
      it 'tracks "signed-up" without affiliate info' do
        expect(adapter)
          .to receive(:track)
          .with(event: 'signed-up', user: user, params: {})

        track('signed-up', user: user)
      end
    end

    context 'when promotional signup' do
      before do
        user.source = 'promotional'
        user.utm_source = 'site'
      end

      it 'tracks "signed-up" with promotional info' do
        plan = PromotionalPlan.new

        params = {
          promotional_identifier: user.utm_source,
          source: 'promotional',
          trial_period: plan.duration,
          trial_subscription: plan.subscription_type,
          credit_card_signup: false
        }

        expect(adapter)
          .to receive(:track)
          .with(event: 'signed-up', user: user, params: params)

        expect(adapter)
          .to receive(:tag_users)
          .with('Promotional', [user])

        track('signed-up', user: user)
      end
    end

    context 'when affiliate signup without partner record' do
      it 'tracks "signed-up" with affiliate info' do
        affiliate_information = create :affiliate_information, user: user
        params = {
          affiliate_identifier: affiliate_information.affiliate_identifier,
          source: 'affiliate'
        }

        expect(adapter)
          .to receive(:track)
          .with(event: 'signed-up', user: user, params: params)

        expect(adapter)
          .to receive(:tag_users)
          .with('Affiliate', [user])

        track('signed-up', user: user)
      end
    end

    context 'when affiliate signup with partner record' do
      it 'tracks "signed-up" with affiliate info' do
        affiliate_information = create :affiliate_information, user: user
        partner = create :partner, affiliate_identifier: affiliate_information.affiliate_identifier

        params = {
          affiliate_identifier: affiliate_information.affiliate_identifier,
          source: 'affiliate',
          trial_period: partner.partner_plan.duration,
          trial_subscription: partner.partner_plan.subscription_type,
          credit_card_signup: partner.require_credit_card
        }

        expect(adapter)
          .to receive(:track)
          .with(event: 'signed-up', user: user, params: params)

        expect(adapter)
          .to receive(:tag_users)
          .with('Affiliate', [user])

        track('signed-up', user: user)
      end
    end
  end

  describe '#auto_renewed_subscription' do
    let(:event) { 'auto-renewed-subscription' }
    let(:site) { create :site, :pro }
    let(:subscription) { site.current_subscription }

    before { allow(adapter).to receive(:tag_users) }

    it 'tracks "auto-renewed-subscription"' do
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

  describe '#paid_bill' do
    let(:event) { 'paid-bill' }
    let(:site) { create :site, :pro }
    let(:subscription) { site.current_subscription }

    before { allow(adapter).to receive(:tag_users) }

    it 'tracks "paid-bill"' do
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
  end

  describe '#used_sender_referral_coupon' do
    let(:event) { 'used-sender-referral-coupon' }
    let(:site) { create :site, :pro }
    let(:subscription) { site.current_subscription }

    it 'tracks "used-sender-referral-coupon"' do
      expect(adapter)
        .to receive(:track)
        .with(event: event, user: user, params: {
          subscription: subscription.name,
          schedule: subscription.schedule,
          site_url: site.url,
          trial_days: 0
        })

      track(event, user: user, subscription: subscription)
    end
  end

  describe '#used_recipient_referral_coupon' do
    let(:event) { 'used-recipient-referral-coupon' }
    let(:site) { create :site, :pro }
    let(:subscription) { site.current_subscription }

    it 'tracks "used-recipient-referral-coupon"' do
      expect(adapter)
        .to receive(:track)
        .with(event: event, user: user, params: {
          subscription: subscription.name,
          schedule: subscription.schedule,
          site_url: site.url,
          trial_days: 0
        })

      track(event, user: user, subscription: subscription)
    end
  end

  describe '#granted_free_days' do
    let(:event) { 'granted-free-days' }
    let(:site) { create :site, :pro }
    let(:subscription) { site.current_subscription }

    before { allow(adapter).to receive(:tag_users) }

    it 'tracks "granted-free-days"' do
      expect(adapter)
        .to receive(:track)
        .with(event: event, user: user, params: {
          site_url: site.url,
          subscription: subscription.name,
          schedule: subscription.schedule,
          free_days: 10
        })

      track(event, user: user, subscription: subscription, free_days: 10)
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

  describe '#added_credit_card' do
    let(:event) { 'added-credit-card' }

    it 'tracks "added-credit-card"' do
      expect(adapter)
        .to receive(:track)
        .with(event: event, user: user, params: {
          site_url: site.url,
          subscription: 'Free',
          schedule: 'monthly'
        })

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

  shared_examples 'change_subscription' do
    it 'tracks event' do
      expect(adapter)
        .to receive(:track)
        .with(event: event, user: user, params: {
          amount: subscription.amount,
          subscription: subscription.name,
          schedule: subscription.schedule,
          site_url: site.url,
          trial_days: 0,
          previous_subscription: previous_subscription.name,
          previous_subscription_amount: previous_subscription.amount,
          previous_subscription_schedule: previous_subscription.schedule
        })

      track(event,
        user: user,
        subscription: subscription,
        previous_subscription: previous_subscription)
    end

    it 'tags users with "Paid"' do
      expect(adapter)
        .to receive(:tag_users)
        .with('Paid', anything)

      expect(adapter).to receive(:track)

      track(event,
        user: user,
        subscription: subscription,
        previous_subscription: previous_subscription)
    end

    it 'tags users with new "Subscription.name" tags' do
      expect(adapter)
        .to receive(:tag_users)
        .with(subscription.name, anything)

      expect(adapter).to receive(:track)

      track(event,
        user: user,
        subscription: subscription,
        previous_subscription: previous_subscription)
    end

    it 'untags owners from previous "Subscription.name" tags' do
      expect(adapter)
        .to receive(:untag_users)
        .with(previous_subscription.name, anything)

      expect(adapter).to receive(:track)

      track(event,
        user: user,
        subscription: subscription,
        previous_subscription: previous_subscription)
    end
  end

  describe '#upgraded_subscription' do
    let(:event) { 'upgraded-subscription' }
    let(:site) { create :site, :pro }
    let(:credit_card) { create :credit_card }
    let(:subscription) { site.current_subscription }
    let(:previous_subscription) { site.previous_subscription }

    before do
      stub_cyber_source(:purchase)
      ChangeSubscription.new(site, { subscription: 'enterprise' }, credit_card).call
    end

    before { allow(adapter).to receive(:tag_users) }
    before { allow(adapter).to receive(:untag_users) }

    include_examples 'change_subscription'
  end

  describe '#downgraded_subscription' do
    let(:event) { 'upgraded-subscription' }
    let(:site) { create :site, :enterprise }
    let(:credit_card) { create :credit_card }
    let(:subscription) { site.current_subscription }
    let(:previous_subscription) { site.previous_subscription }

    before do
      ChangeSubscription.new(site, { subscription: 'pro' }, credit_card).call
    end

    before { allow(adapter).to receive(:tag_users) }
    before { allow(adapter).to receive(:untag_users) }

    include_examples 'change_subscription'

    context 'when downgrading to Free' do
      before do
        DowngradeSiteToFree.new(site).call
      end

      it 'untags owners of "Paid" tag' do
        expect(adapter)
          .to receive(:untag_users)
          .with('Paid', anything)

        expect(adapter).to receive(:track)

        track(event,
          user: user,
          subscription: subscription,
          previous_subscription: previous_subscription)
      end
    end
  end

  describe '#referred_friend' do
    let(:event) { 'referred-friend' }
    let(:referral) { create :referral, site: site }

    it 'tracks "referred-friend"' do
      expect(adapter)
        .to receive(:track)
        .with(event: event, user: user, params: {
          email: referral.email,
          site_url: site.url
        })

      track(event, user: user, referral: referral)
    end
  end
end
