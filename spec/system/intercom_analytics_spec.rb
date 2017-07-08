describe IntercomAnalytics do
  def fire_event(event, **options)
    IntercomAnalytics.event(event, **options)
  end

  let(:intercom) { instance_double(Intercom::Client) }

  before { allow(Intercom::Client).to receive(:new).and_return(intercom) }

  describe '"subscription_changed" event', :freeze do
    let!(:owner) { create :user }
    let!(:site) { create :site, :pro, user: owner }

    let(:data) do
      {
        event_name: 'changed-subscription',
        user_id: owner.id,
        created_at: Time.current.to_i,
        metadata: { subscription: 'Pro', schedule: 'monthly' }
      }
    end

    let(:tags) { double('tags') }

    it 'sends "changed-subscription" to intercom for each owner' do
      expect(intercom).to receive_message_chain(:events, :create).with(data)
      expect(intercom).to receive(:tags).and_return(tags).twice
      expect(tags).to receive(:tag).with(name: 'Paid', users: [user_id: owner.id])
      expect(tags).to receive(:tag).with(name: 'Pro', users: [user_id: owner.id])

      fire_event 'subscription_changed', site: site
    end
  end
end
