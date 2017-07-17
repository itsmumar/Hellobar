describe TrackEvent, :freeze do
  def fire_event(event, **options)
    TrackEvent.new(event, **options).call
  end

  let(:intercom) { instance_double(Intercom::Client) }
  let!(:owner) { create :user }
  let!(:site) { create :site, :pro, :with_rule, user: owner }

  before { allow(Intercom::Client).to receive(:new).and_return(intercom) }
  around { |example| perform_enqueued_jobs(&example) }

  describe '"changed_subscription" event' do
    let(:tags) { double('tags') }

    it 'sends "changed-subscription" to intercom and tag owners' do
      expect(intercom).to receive_message_chain(:events, :create).with(
        event_name: 'changed-subscription',
        user_id: owner.id,
        created_at: Time.current.to_i,
        metadata: { subscription: 'Pro', schedule: 'monthly' }
      )
      expect(intercom).to receive(:tags).and_return(tags).twice
      expect(tags).to receive(:tag).with(name: 'Paid', users: [user_id: owner.id])
      expect(tags).to receive(:tag).with(name: 'Pro', users: [user_id: owner.id])

      fire_event :changed_subscription, site: site, user: owner
    end
  end

  describe '"created_bar" event' do
    let!(:site_element) { create :site_element, site: site }

    it 'sends "created-bar" to intercom' do
      expect(intercom).to receive_message_chain(:events, :create).with(
        event_name: 'created-bar',
        user_id: owner.id,
        created_at: Time.current.to_i,
        metadata: { bar_type: site_element.type, goal: site_element.element_subtype }
      )
      fire_event :created_bar, site_element: site_element, user: owner
    end
  end

  describe '"created_contact_list" event' do
    let!(:contact_list) { create :contact_list, site: site }

    it 'sends "created-contact-list" to intercom' do
      expect(intercom).to receive_message_chain(:events, :create).with(
        event_name: 'created-contact-list',
        user_id: owner.id,
        created_at: Time.current.to_i,
        metadata: { site_url: site.url }
      )
      fire_event :created_contact_list, contact_list: contact_list, user: owner
    end
  end

  describe '"created_site" event' do
    it 'sends "created-site" to intercom' do
      expect(intercom).to receive_message_chain(:events, :create).with(
        event_name: 'created-site',
        user_id: owner.id,
        created_at: Time.current.to_i,
        metadata: { url: site.url }
      )
      fire_event :created_site, site: site, user: owner
    end
  end

  describe '"invited_member" event' do
    it 'sends "invited-member" to intercom' do
      expect(intercom).to receive_message_chain(:events, :create).with(
        event_name: 'invited-member',
        user_id: owner.id,
        created_at: Time.current.to_i,
        metadata: { site_url: site.url }
      )
      fire_event :invited_member, site: site, user: owner
    end
  end
end
