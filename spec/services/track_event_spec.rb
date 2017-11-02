describe TrackEvent, :freeze do
  def fire_event(event, **options)
    TrackEvent.new(event, **options).call
  end

  let(:intercom) { instance_double(Intercom::Client) }
  let(:diamond) { instance_double(Diamond::Client) }
  let(:diamond_endpoint) { 'http://foo.bar/hbprod' }
  let(:owner) { create :user }
  let(:site) { create :site, :pro, :with_rule, user: owner }

  before do
    allow(Intercom::Client).to receive(:new).and_return(intercom)
    allow(Diamond::Client).to receive(:new).and_return(diamond)
    allow(Settings).to receive(:diamond_endpoint).and_return(diamond_endpoint)

    # skip A/B assignment
    allow_any_instance_of(User).to receive(:add_to_onboarding_campaign)
  end

  around { |example| perform_enqueued_jobs(&example) }

  describe '"signed_up" event' do
    it 'sends "signed-up" event to intercom and diamond' do
      expect(intercom).to receive_message_chain(:events, :create).with(
        event_name: 'signed-up',
        user_id: owner.id,
        created_at: Time.current.to_i
      )

      expect(diamond).to receive(:track).with(
        event: 'Signed Up',
        identities: {
          user_id: owner.id,
          user_email: owner.email
        },
        timestamp: owner.created_at.to_f
      )

      fire_event :signed_up, user: owner
    end
  end

  describe '"changed_subscription" event' do
    let(:tags) { double('tags') }

    it 'sends "changed-subscription" to intercom and diamond, tags owners' do
      expect(intercom).to receive_message_chain(:events, :create).with(
        event_name: 'changed-subscription',
        user_id: owner.id,
        created_at: Time.current.to_i,
        metadata: { subscription: 'Pro', schedule: 'monthly' }
      )
      expect(intercom).to receive(:tags).and_return(tags).twice
      expect(tags).to receive(:tag).with(name: 'Paid', users: [user_id: owner.id])
      expect(tags).to receive(:tag).with(name: 'Pro', users: [user_id: owner.id])

      expect(diamond).to receive(:track).with(
        event: 'Changed Subscription',
        identities: {
          site_id: site.id,
          user_id: owner.id,
          user_email: owner.email
        },
        timestamp: site.created_at.to_f,
        properties: {
          subscription: 'Pro',
          subscription_schedule: 'monthly'
        }
      )

      # track paid/subscription status on owner
      expect(diamond).to receive(:track).with(
        identities: {
          user_id: owner.id,
          user_email: owner.email
        },
        timestamp: site.created_at.to_f,
        properties: {
          paid: true,
          subscription: 'Pro'
        }
      )

      fire_event :changed_subscription, site: site, user: owner
    end

    context 'without current_subscription' do
      before { site.current_subscription.destroy }

      it 'does not raise error' do
        expect(intercom).to receive_message_chain(:events, :create)
        expect(intercom).to receive_message_chain(:tags, :tag)
        expect(diamond).to receive(:track).twice
        fire_event :changed_subscription, site: site, user: owner
      end
    end
  end

  describe '"created_bar" event' do
    let!(:site_element) { create :site_element, site: site }

    it 'sends "created-bar" to intercom and diamond' do
      expect(intercom).to receive_message_chain(:events, :create).with(
        event_name: 'created-bar',
        user_id: owner.id,
        created_at: Time.current.to_i,
        metadata: { bar_type: site_element.type, goal: site_element.element_subtype }
      )

      expect(diamond).to receive(:track).with(
        event: 'Created Bar',
        identities: {
          site_id: site.id,
          user_id: owner.id,
          user_email: owner.email
        },
        timestamp: site.created_at.to_f,
        properties: {
          element_type: site_element.type,
          element_goal: site_element.element_subtype
        }
      )

      fire_event :created_bar, site_element: site_element, user: owner
    end
  end

  describe '"created_contact_list" event' do
    let!(:contact_list) { create :contact_list, site: site }

    it 'sends "created-contact-list" to intercom and diamond' do
      expect(intercom).to receive_message_chain(:events, :create).with(
        event_name: 'created-contact-list',
        user_id: owner.id,
        created_at: Time.current.to_i,
        metadata: { site_url: site.url }
      )

      expect(diamond).to receive(:track).with(
        event: 'Created Contact List',
        identities: {
          site_id: site.id,
          user_id: owner.id,
          user_email: owner.email
        },
        timestamp: contact_list.created_at.to_f,
        properties: {
          site_url: contact_list.site.url
        }
      )

      fire_event :created_contact_list, contact_list: contact_list, user: owner
    end
  end

  describe '"created_site" event' do
    it 'sends "created-site" to intercom and diamond' do
      expect(intercom).to receive_message_chain(:events, :create).with(
        event_name: 'created-site',
        user_id: owner.id,
        created_at: Time.current.to_i,
        metadata: { url: site.url }
      )

      expect(diamond).to receive(:track).with(
        event: 'Created Site',
        identities: {
          site_id: site.id,
          user_id: owner.id,
          user_email: owner.email
        },
        timestamp: site.created_at.to_f,
        properties: {
          site_url: site.url
        }
      )

      fire_event :created_site, site: site, user: owner
    end
  end

  describe '"invited_member" event' do
    it 'sends "invited-member" to intercom and diamond' do
      expect(intercom).to receive_message_chain(:events, :create).with(
        event_name: 'invited-member',
        user_id: owner.id,
        created_at: Time.current.to_i,
        metadata: { site_url: site.url }
      )

      expect(diamond).to receive(:track).with(
        event: 'Invited Member',
        identities: {
          site_id: site.id,
          user_id: owner.id,
          user_email: owner.email
        },
        timestamp: site.created_at.to_f,
        properties: {
          site_url: site.url
        }
      )

      fire_event :invited_member, site: site, user: owner
    end
  end
end
