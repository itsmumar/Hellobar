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
          .with(event: 'signed-up', user: user, params: { admin_link: "https://app.hellobar.com/admin/users/#{ user.id }" })

        expect(adapter)
          .to receive(:tag_users)
          .with('Free', [user])

        track('signed-up', user: user)
      end
    end

    context 'when promotional signup' do
      let(:utm_source) { 'site' }

      it 'tracks "signed-up" with promotional info' do
        plan = PromotionalPlan.new

        params = {
          promotional_identifier: utm_source,
          source: 'promotional',
          trial_period: plan.duration,
          trial_subscription: plan.subscription_type,
          credit_card_signup: false,
          admin_link: "https://app.hellobar.com/admin/users/#{ user.id }"
        }

        expect(adapter)
          .to receive(:track)
          .with(event: 'signed-up', user: user, params: params)

        expect(adapter)
          .to receive(:tag_users)
          .with('Promotional', [user])

        expect(adapter)
          .to receive(:tag_users)
          .with('Free', [user])

        expect(adapter)
          .to receive(:update_user)
          .with(user: user, params: params)

        track('signed-up', user: user, promotional_signup: true, utm_source: utm_source)
      end
    end

    context 'when affiliate signup without partner record' do
      it 'tracks "signed-up" with affiliate info' do
        affiliate_information = create :affiliate_information, user: user
        params = {
          affiliate_identifier: affiliate_information.affiliate_identifier,
          source: 'affiliate',
          admin_link: "https://app.hellobar.com/admin/users/#{ user.id }"
        }

        expect(adapter)
          .to receive(:track)
          .with(event: 'signed-up', user: user, params: params)

        expect(adapter)
          .to receive(:tag_users)
          .with('Affiliate', [user])

        expect(adapter)
          .to receive(:tag_users)
          .with('Free', [user])

        expect(adapter)
          .to receive(:update_user)
          .with(user: user, params: params)

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
          credit_card_signup: partner.require_credit_card,
          admin_link: "https://app.hellobar.com/admin/users/#{ user.id }"
        }

        expect(adapter)
          .to receive(:track)
          .with(event: 'signed-up', user: user, params: params)

        expect(adapter)
          .to receive(:tag_users)
          .with('Affiliate', [user])

        expect(adapter)
          .to receive(:tag_users)
          .with('Free', [user])

        expect(adapter)
          .to receive(:update_user)
          .with(user: user, params: params)

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
        .with(event: event, user: user, params: { site_url: site.url, site_id: site.id })

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
    # let(:event) { 'created-site' }
    let(:site) { create :site, :with_user }
    let(:second_site) { create :site, :with_user }

    it 'tracks "created-site"' do
      expect(adapter)
        .to receive(:tag_users)
        .with("#{ user.sites.count } Sites", site.owners)

      expect(adapter)
        .to receive(:untag_users)
        .with("#{ (user.sites.count - 1) } Sites", site.owners)

      expect(adapter)
        .to receive(:track)
        .with(event: 'created-site', user: user, params: { url: site.url, site_id: site.id })

      expect(adapter).to receive(:update_user)

      track('created-site', user: user, site: site)
    end
  end

  describe '#added_credit_card' do
    let(:event) { 'added-credit-card' }

    it 'tracks "added-credit-card"' do
      expect(adapter)
        .to receive(:track)
        .with(event: event, user: user, params: {
          site_url: site.url,
          site_id: site.id,
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
        .to receive(:tag_users)
        .with(site.install_type, anything)

      expect(adapter)
        .to receive(:track)
        .with(event: event, user: user,
              params: {
                url: site.url,
                site_id: site.id,
                install_type: site.install_type
              })

      track(event, user: user, site: site)
    end
  end

  describe '#uninstalled_script' do
    let(:event) { 'uninstalled-script' }

    it 'tracks "uninstalled-script"' do
      expect(adapter)
        .to receive(:track)
        .with(event: event, user: user, params: { url: site.url, site_id: site.id })

      track(event, user: user, site: site)
    end
  end

  describe '#not_installed_script' do
    let(:event) { 'not-installed-script' }

    it 'tracks "not_installed_script"' do
      expect(adapter)
        .to receive(:track)
        .with(event: 'not-yet-installed-script', user: user, params: { url: site.url, site_id: site.id })

      track(event, user: user, site: site)
    end
  end

  describe '#Inactive_user' do
    let(:event) { 'Inactive-user' }

    it 'tracks "Inactive_user"' do
      expect(adapter)
        .to receive(:track)
        .with(event: 'Inactive', user: user, params: { last_sign_in_at: user.last_sign_in_at, site_url: site.url, site_id: site.id })

      track(event, user: user, site: site)
    end
  end

  describe '#ab_test_created' do
    let(:event) { 'ab-test-created' }
    let(:site_element) { create :site_element, type: 'Bar' }

    it 'tracks "ab_test_created" for bar' do
      expect(adapter)
        .to receive(:track)
        .with(event: 'ab-test-created', user: user,
          params: {
            goal: site_element.element_subtype,
            type: site_element.type,
            site_url: site_element.site.url,
            site_id: site_element.site.id
          })

      track(event, user: user, site_element: site_element)
    end
  end

  describe '#ab_test_not_created' do
    let(:event) { 'ab-test-not-created' }

    it 'tracks "ab_test_not_created"' do
      expect(adapter)
        .to receive(:track)
        .with(event: 'no-ab-test', user: user, params: { site_url: site.url, site_id: site.id })

      track(event, user: user, site: site)
    end
  end

  describe '#bar_not_created' do
    let(:event) { 'bar-not-created' }

    it 'tracks "bar_not_created"' do
      expect(adapter)
        .to receive(:track)
        .with(event: 'not-yet-created-popup', user: user, params: { site_url: site.url, site_id: site.id })

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
          site_url: contact_list.site.url,
          site_id: contact_list.site.id
        })

      track(event, user: user, contact_list: contact_list)
    end
  end

  describe '#created_bar' do
    let(:event) { 'created-bar' }
    let(:site_element) { create :site_element, type: 'Bar' }
    let(:modal_element) { create :site_element, type: 'Modal' }

    it 'tracks "created-popup" for bar' do
      expect(adapter)
        .to receive(:track)
        .with(event: 'created-popup', user: user,
          params: {
            goal: site_element.element_subtype,
            type: site_element.type,
            theme_id: site_element.theme_id,
            enable_gdpr: site_element.enable_gdpr,
            show_branding: site_element.show_branding,
            headline: site_element.headline,
            use_default_image: site_element.use_default_image,
            link_text: site_element.link_text,
            use_question: site_element.use_question,
            site_url: site_element.site.url,
            site_id: site_element.site.id
          })

      track(event,
        user: user,
        site_element: site_element)
    end

    it 'tracks "created-popup" for modal' do
      expect(adapter)
        .to receive(:track)
        .with(event: 'created-popup', user: user,
          params: {
            goal: site_element.element_subtype,
            type: 'Modal',
            theme_id: modal_element.theme_id,
            enable_gdpr: modal_element.enable_gdpr,
            show_branding: modal_element.show_branding,
            headline: modal_element.headline,
            use_default_image: modal_element.use_default_image,
            link_text: modal_element.link_text,
            use_question: modal_element.use_question,
            site_url: modal_element.site.url,
            site_id: modal_element.site.id
          })

      track(event,
        user: user,
        site_element: modal_element)
    end
  end

  describe '#updated_bar' do
    let(:event) { 'updated-bar' }
    let(:site_element) { create :site_element, type: 'Bar' }
    let(:modal_element) { create :site_element, type: 'Modal' }

    it 'tracks "updated-popup" for bar' do
      site_element.update(wiggle_button: true)
      expect(adapter)
        .to receive(:track)
        .with(event: 'updated-popup', user: user,
          params: {
            goal: site_element.element_subtype,
            type: site_element.type,
            theme_id: site_element.theme_id,
            enable_gdpr: site_element.enable_gdpr,
            show_branding: site_element.show_branding,
            headline: site_element.headline,
            use_default_image: site_element.use_default_image,
            link_text: site_element.link_text,
            use_question: site_element.use_question,
            site_url: site_element.site.url,
            site_id: site_element.site.id
          })

      track(event,
        user: user,
        site_element: site_element)
    end

    it 'tracks "updated-popup" for modal' do
      modal_element.update(wiggle_button: true)
      expect(adapter)
        .to receive(:track)
        .with(event: 'updated-popup', user: user,
          params: {
            goal: site_element.element_subtype,
            type: 'Modal',
            theme_id: modal_element.theme_id,
            enable_gdpr: modal_element.enable_gdpr,
            show_branding: modal_element.show_branding,
            headline: modal_element.headline,
            use_default_image: modal_element.use_default_image,
            link_text: modal_element.link_text,
            use_question: modal_element.use_question,
            site_url: modal_element.site.url,
            site_id: modal_element.site.id
          })

      track(event,
        user: user,
        site_element: modal_element)
    end
  end

  shared_examples 'change_subscription' do
    it 'tracks event' do
      params = {
        amount: subscription.amount,
        subscription: subscription.name,
        schedule: subscription.schedule,
        site_url: site.url,
        site_id: site.id,
        trial_days: 0,
        previous_subscription: previous_subscription.name,
        previous_subscription_amount: previous_subscription.amount,
        previous_subscription_schedule: previous_subscription.schedule,
        subscription_start_date: subscription.created_at
      }

      expect(adapter)
        .to receive(:track)
        .with(event: event, user: user, params: params)

      expect(adapter).to receive(:update_user)

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
      ChangeSubscription.new(site, { subscription: 'elite' }, credit_card).call
    end

    before { allow(adapter).to receive(:tag_users) }
    before { allow(adapter).to receive(:untag_users) }
    before { allow(adapter).to receive(:update_user) }

    include_examples 'change_subscription'
  end

  describe '#downgraded_subscription' do
    let(:event) { 'downgraded-subscription' }
    let(:site) { create :site, :elite }
    let(:credit_card) { create :credit_card }
    let(:subscription) { site.current_subscription }
    let(:previous_subscription) { site.previous_subscription }

    before do
      ChangeSubscription.new(site, { subscription: 'pro' }, credit_card).call
    end

    before { allow(adapter).to receive(:tag_users) }
    before { allow(adapter).to receive(:untag_users) }
    before { allow(adapter).to receive(:update_user) }

    include_examples 'change_subscription'

    context 'when downgrading to Free' do
      before do
        DowngradeSiteToFree.new(site).call
      end

      it 'untags owners of "previous subscription" tag when downgrading' do
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

  describe '#exceeded_views_limit' do
    let(:event) { 'exceeded-views-limit' }
    let(:number_of_views) { 999 }
    let(:limit) { 100 }

    it 'tracks "exceeded-views-limit"' do
      params = {}

      params[:site_id] = site.id
      params[:site_url] = site.url
      params[:number_of_views] = number_of_views
      params[:limit] = limit
      params[:subscription] = 'Free'
      params[:schedule] = 'monthly'
      params[:overage_count] = site.overage_count
      params[:visit_overage] = Subscription::Free.new.visit_overage
      params[:overage_fees] = 5 * site.overage_count
      params[:upgrade_link] = "https://app.hellobar.com/sites/#{ site.id }/edit"

      expect(adapter)
        .to receive(:track)
        .with(event: event, user: user, params: params)

      expect(adapter).to receive(:update_user)

      track(event, site: site, user: user, limit: limit, number_of_views: number_of_views)
    end
  end

  describe '#updated_site_count' do
    let(:site) { create :site }
    let(:other_site) { create :site }

    it 'tracks "updated-site-count"' do
      site.owners << user
      other_site.owners << user

      expect(adapter)
        .to receive(:untag_users)
        .with("#{ (user.sites.count - 1) } Sites", [user])

      expect(adapter)
        .to receive(:untag_users)
        .with("#{ user.sites.count } Sites", [user])

      expect(adapter)
        .to receive(:untag_users)
        .with("#{ (user.sites.count + 1) } Sites", [user])

      expect(adapter)
        .to receive(:untag_users)
        .with('Multiple Sites', [user])

      expect(adapter)
        .to receive(:tag_users)
        .with("#{ user.sites.count } Sites", [user])

      expect(adapter)
        .to receive(:tag_users)
        .with('Multiple Sites', [user])

      track('updated-site-count', user: user)
    end
  end

  describe '#added_dme' do
    let(:site) { create :site, :elite, user: user }

    it 'tracks "fired DME"' do
      expect(adapter)
        .to receive(:track)
        .with(event: 'add-dme', user: user, params: {})

      expect(adapter)
        .to receive(:tag_users)
        .with('DME', [site.users.first])

      expect(adapter)
        .to receive(:tag_users)
        .with('Elite', [site.users.first])

      track('added_dme', user: user, highest_subscription_name: 'Elite')
    end
  end

  describe '#free_overage' do
    let(:site) { create :site, user: user }

    it 'tracks "fired free overage"' do
      expect(adapter)
        .to receive(:track)
        .with(event: 'free-overage', user: user,
          params: {
            site_id: site.id,
            site_url: site.url,
            limit: 5000,
            overage_count: site.overage_count
          })

      expect(adapter).to receive(:update_user)

      track('free-overage', user: user, site: site)
    end
  end

  describe '#triggered_payment_checkout' do
    let(:source) { 'foo bar' }

    it 'tracks "triggered-payment-checkout"' do
      expect(adapter)
        .to receive(:track)
        .with(event: 'triggered-payment-checkout',
          user: user,
          params: {
            source: source
          })

      expect(adapter).to receive(:update_user)

      track('triggered-payment-checkout', user: user, source: source)
    end
  end

  describe '#triggered_upgrade_account' do
    let(:source) { 'foo bar' }

    it 'tracks "triggered-upgrade-account"' do
      expect(adapter)
        .to receive(:track)
        .with(event: 'triggered-upgrade-account',
          user: user,
          params: {
            source: source
          })

      expect(adapter)
        .to receive(:update_user)

      track('triggered-upgrade-account', user: user, source: source)
    end

    describe '#auto_upgrade_to_elite' do
      let(:site) { create :site, user: user }

      it 'tracks "fired auto-upgrade-to-elite"' do
        expect(adapter)
          .to receive(:track)
          .with(event: 'auto-upgrade-to-elite', user: user,
            params: {
              site_id: site.id,
              site_url: site.url
            })

        expect(adapter).to receive(:update_user)

        track('auto-upgrade-to-elite', user: user, site: site)
      end
    end
  end

  describe '#triggered_payment_checkout' do
    let(:source) { 'foo bar' }

    it 'tracks "triggered-payment-checkout"' do
      expect(adapter)
        .to receive(:track)
        .with(event: 'triggered-payment-checkout',
          user: user,
          params: {
            source: source
          })

      expect(adapter).to receive(:update_user)

      track('triggered-payment-checkout', user: user, source: source)
    end
  end

  describe '#triggered_upgrade_account' do
    let(:source) { 'foo bar' }

    it 'tracks "triggered-upgrade-account"' do
      expect(adapter)
        .to receive(:track)
        .with(event: 'triggered-upgrade-account',
          user: user,
          params: {
            source: source
          })

      expect(adapter).to receive(:update_user)

      track('triggered-upgrade-account', user: user, source: source)
    end
  end

  describe '#auto_upgrade_to_elite' do
    let(:site) { create :site, user: user }

    it 'tracks "fired auto-upgrade-to-elite"' do
      expect(adapter)
        .to receive(:track)
        .with(event: 'auto-upgrade-to-elite', user: user,
          params: {
            site_id: site.id,
            site_url: site.url
          })

      expect(adapter).to receive(:update_user)

      track('auto-upgrade-to-elite', user: user, site: site)
    end
  end
end
