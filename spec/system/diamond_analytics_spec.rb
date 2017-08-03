describe DiamondAnalytics do
  let(:analytics) { described_class.new }
  let(:tracker) { double(:tracker) }
  let(:diamond_endpoint) { 'http://foobar.com/hbprod' }
  let(:user) { create(:user, :with_site) }
  let(:site) { user.sites.first }
  let(:rule) { create(:rule, site: site) }
  let(:site_element) { create(:site_element, :email, rule: rule) }
  let(:contact_list) { site_element.contact_list }

  before do
    allow(analytics).to receive(:diamond).and_return(tracker)
    allow(Settings).to receive(:diamond_endpoint).and_return(diamond_endpoint)
  end

  describe '#signed_up' do
    subject { analytics.signed_up(user: user) }

    it 'tracks the invited-member event' do
      expect(tracker).to receive(:track).with(
        event: 'Signed Up',
        identities: {
          user_id: user.id,
          user_email: user.email
        },
        timestamp: user.created_at.to_f
      )

      subject
    end

    context 'when tracking is disabled' do
      before do
        expect(analytics).to receive(:enabled?).and_return(false)
      end

      it 'does not track' do
        expect(tracker).not_to receive(:track)

        subject
      end
    end
  end

  describe '#invited_member' do
    subject { analytics.invited_member(site: site, user: user) }

    it 'tracks the invited-member event' do
      expect(tracker).to receive(:track).with(
        event: 'Invited Member',
        identities: {
          site_id: site.id,
          user_id: user.id,
          user_email: user.email
        },
        timestamp: user.created_at.to_f,
        properties: {
          site_url: site.url
        }
      )

      subject
    end

    context 'when tracking is disabled' do
      before do
        expect(analytics).to receive(:enabled?).and_return(false)
      end

      it 'does not track' do
        expect(tracker).not_to receive(:track)

        subject
      end
    end
  end

  describe '#created_site' do
    subject { analytics.created_site(site: site, user: user) }

    it 'tracks the invited-member event' do
      expect(tracker).to receive(:track).with(
        event: 'Created Site',
        identities: {
          site_id: site.id,
          user_id: user.id,
          user_email: user.email
        },
        timestamp: site.created_at.to_f,
        properties: {
          site_url: site.url
        }
      )

      subject
    end

    context 'when tracking is disabled' do
      before do
        expect(analytics).to receive(:enabled?).and_return(false)
      end

      it 'does not track' do
        expect(tracker).not_to receive(:track)

        subject
      end
    end
  end

  describe '#created_contact_list' do
    subject { analytics.created_contact_list(contact_list: contact_list, user: user) }

    it 'tracks the invited-member event' do
      expect(tracker).to receive(:track).with(
        event: 'Created Contact List',
        identities: {
          site_id: contact_list.site.id,
          user_id: user.id,
          user_email: user.email
        },
        timestamp: contact_list.created_at.to_f,
        properties: {
          site_url: contact_list.site.url
        }
      )

      subject
    end

    context 'when tracking is disabled' do
      before do
        expect(analytics).to receive(:enabled?).and_return(false)
      end

      it 'does not track' do
        expect(tracker).not_to receive(:track)

        subject
      end
    end
  end

  describe '#created_bar' do
    subject { analytics.created_bar(site_element: site_element, user: user) }

    it 'tracks the invited-member event' do
      expect(tracker).to receive(:track).with(
        event: 'Created Bar',
        identities: {
          site_id: site_element.site_id,
          user_id: user.id,
          user_email: user.email
        },
        timestamp: site_element.created_at.to_f,
        properties: {
          element_type: site_element.type,
          element_goal: site_element.element_subtype
        }
      )

      subject
    end

    context 'when tracking is disabled' do
      before do
        expect(analytics).to receive(:enabled?).and_return(false)
      end

      it 'does not track' do
        expect(tracker).not_to receive(:track)

        subject
      end
    end
  end

  describe '#changed_subscription' do
    let!(:subscription) { create(:subscription, :pro, site: site) }

    subject { analytics.changed_subscription(site: site, user: user) }

    it 'tracks the invited-member event' do
      # subscription.created_at.to_f was causing errors
      subscription.reload

      expect(tracker).to receive(:track).with(
        event: 'Changed Subscription',
        identities: {
          site_id: site.id,
          user_id: user.id,
          user_email: user.email
        },
        timestamp: subscription.created_at.to_f,
        properties: {
          subscription: subscription.name,
          subscription_schedule: subscription.schedule
        }
      )

      site.owners.each do |owner|
        expect(tracker).to receive(:track).with(
          identities: {
            user_id: owner.id,
            user_email: owner.email
          },
          timestamp: subscription.created_at.to_f,
          properties: {
            paid: subscription.amount.positive?,
            subscription: subscription.name
          }
        )
      end

      subject
    end

    context 'when tracking is disabled' do
      before do
        expect(analytics).to receive(:enabled?).and_return(false).twice
      end

      it 'does not track' do
        expect(tracker).not_to receive(:track)

        subject
      end
    end
  end
end
